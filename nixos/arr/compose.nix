# Declarative management of the arr docker compose stack.
#
# The compose file lives in this repo and runs from the nix store, while all
# state (./config, ./data, ./cache) and the secrets in .env stay on the host in
# /home/arr/arr. `--project-directory` anchors the compose file's relative
# paths there and keeps the compose project name "arr", so existing containers
# are reconciled instead of a second stack being created.
{pkgs, ...}: let
  projectDir = "/home/arr/arr";
  composeFile = ./compose/docker-compose.yml;

  # Convenience wrapper: bakes in the store path of the compose file and the
  # project directory, so `arr-compose <cmd>` behaves like the full
  # `docker compose -f ... --project-directory /home/arr/arr <cmd>` line.
  arr-compose = pkgs.writeShellApplication {
    name = "arr-compose";
    runtimeInputs = [pkgs.docker-compose];
    text = ''
      if [ "$#" -eq 0 ]; then
        set -- ps
      fi
      exec docker-compose -f ${composeFile} --project-directory ${projectDir} "$@"
    '';
  };

  media-watchdog = pkgs.writeShellScript "arr-media-watchdog" (builtins.readFile ./compose/media-watchdog.sh);
  media-hook = pkgs.writeShellScript "arr-media-hook" (builtins.readFile ./compose/media-hook.sh);

  # sha256 of the token accepted by the HTTP hook. Only the hash lives in the
  # repo; the token itself is kept in the password manager.
  hookTokenHash = "cb7abc71e028205b13ffbc1c487312c1164e72a885e061ee5ddca50f0c8241f9";
in {
  environment.systemPackages = [arr-compose];

  # Also drop it in the project directory. A root-owned symlink to the store,
  # refreshed by systemd-tmpfiles whenever the deployed wrapper changes.
  systemd.tmpfiles.rules = [
    "L+ ${projectDir}/arr-compose - - - - ${arr-compose}/bin/arr-compose"
  ];

  systemd.services.arr-compose = {
    description = "arr docker compose stack";
    wantedBy = ["multi-user.target"];
    requires = ["docker.service" "mnt-media.mount"];
    after = ["docker.service" "network-online.target" "mnt-media.mount"];
    wants = ["network-online.target"];
    # Never reconcile against an unmounted /mnt/media.
    unitConfig.RequiresMountsFor = ["/mnt/media"];
    # A rebuild that changes the compose file reconciles containers instead of
    # stopping and recreating the whole stack.
    reloadIfChanged = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = projectDir;
      TimeoutStartSec = "5min";
      ExecStart = "${arr-compose}/bin/arr-compose up -d --remove-orphans";
      ExecReload = "${arr-compose}/bin/arr-compose up -d --remove-orphans";
    };
  };

  # Safety net for the case where dockerd wins the race and containers come up
  # against the directory *under* /mnt/media: detect it, capture evidence,
  # restart the affected services.
  systemd.services.arr-media-watchdog = {
    description = "arr: recover containers that lost /mnt/media";
    after = ["docker.service" "arr-compose.service"];
    requires = ["docker.service"];
    environment.ARR_COMPOSE = "${arr-compose}/bin/arr-compose";
    path = [
      pkgs.coreutils
      pkgs.docker
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.jq
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "arr-watchdog";
      ExecStart = "${media-watchdog}";
    };
  };

  systemd.timers.arr-media-watchdog = {
    wantedBy = ["timers.target"];
    timerConfig = {
      Unit = "arr-media-watchdog.service";
      OnBootSec = "90s";
      OnUnitActiveSec = "2min";
      AccuracySec = "15s";
    };
  };

  # Manual hook: hit it when playback is broken, it captures evidence first and
  # then restarts the media services. Socket-activated, so nothing runs between
  # requests.
  #   curl 'http://192.168.1.193:9199/hook?token=<token>&note=jellyfin-ipad'
  #   ...&scope=all  restarts every service instead of only the media ones.
  systemd.sockets.arr-hook = {
    wantedBy = ["sockets.target"];
    listenStreams = ["0.0.0.0:9199"];
    socketConfig.Accept = true;
  };

  systemd.services."arr-hook@" = {
    description = "arr media capture/restart hook";
    requires = ["docker.service" "arr-compose.service"];
    after = ["docker.service" "arr-compose.service"];
    environment = {
      ARR_WATCHDOG = "${media-watchdog}";
      ARR_HOOK_TOKEN_HASH = hookTokenHash;
    };
    path = [
      pkgs.coreutils
      pkgs.docker
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.jq
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      StandardInput = "socket";
      StandardOutput = "socket";
      ExecStart = "${media-hook}";
      TimeoutStartSec = "180s";
    };
  };
}
