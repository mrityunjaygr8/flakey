# Declarative management of the arr docker compose stack.
#
# The compose file lives in this repo and runs from the nix store, while all
# state (./config, ./data, ./cache) and the secrets in .env stay on the host in
# /home/arr/arr. `--project-directory` anchors the compose file's relative
# paths there and keeps the compose project name "arr", so existing containers
# are reconciled instead of a second stack being created.
{pkgs, ...}: let
  compose = "${pkgs.docker-compose}/bin/docker-compose -f ${./compose/docker-compose.yml} --project-directory /home/arr/arr";
in {
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
      WorkingDirectory = "/home/arr/arr";
      TimeoutStartSec = "5min";
      ExecStart = "${compose} up -d --remove-orphans";
      ExecReload = "${compose} up -d --remove-orphans";
    };
  };
}
