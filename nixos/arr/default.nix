# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/nixos/nix-conf.nix
    ../../modules/nixos/k3s.nix
    ../../modules/nixos/rex.nix
    ./compose.nix
  ];

  # rex server: unix socket only (/run/rex/server.sock), like kharkanas. A TCP
  # listener would require allowAnonymous = true, i.e. full unauthenticated
  # access for anyone who can reach the port, so remote access goes through an
  # SSH-forwarded socket instead:
  #   ssh -N -L 8091:/run/rex/server.sock arr
  #   rex-rune --endpoint http://127.0.0.1:8091
  # (arr must be in the rex group to open the remote socket.)
  # When Tailscale is added, use `extraListen = [ "tailnet://arr:8091" ]` for
  # identified access instead of anonymous TCP.
  users.groups.rex.members = ["arr"];

  # Expose each flake registry entry as a NIX_PATH entry (/etc/nix/path/<name>).
  # Entries registered by NixOS itself (e.g. 'nixpkgs') have no 'flake'
  # attribute, so fall back to the registry's path.
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source =
        if value.flake != null
        then value.flake
        else value.to.path;
    })
    (lib.filterAttrs
      (_: value: value.flake != null || (value.to.path or null) != null)
      config.nix.registry);

  # FIXME: Add the rest of your current configuration

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = ["ntfs"];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib # for numpy, which is for pandas
    ];
  };
  networking.hostName = "arr"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arr = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gcc
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    openssl
    cachix
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    lazygit
    lazydocker
    neovim
    git
    wget
    docker-compose
    dive
    dig
    ntfs3g
    # podman-compose
  ];
  virtualisation.docker.enable = true;
  # virtualisation.docker.daemonConfig.ipv6 = true;
  # virtualisation.docker.daemonConfig."fixed-cidr-v6" = "fd00::/80";
  virtualisation.docker.daemon.settings = {
    fixed-cidr-v6 = "fd00::/80";
    ipv6 = true;
    live-restore = true;
  };

  # dockerd starts containers with `restart: unless-stopped` as soon as it is
  # up. If that happens before /mnt/media is mounted, those containers bind the
  # empty directory underneath the mount and never see the media disk until
  # they are recreated (library lists fine, playback fails). Wait for the mount
  # attempt to finish, without making docker depend on it: if the disk is
  # missing, docker still starts and arr-media-watchdog reports it.
  # NB: these must be the typed options -- `unitConfig.after` is emitted
  # verbatim and systemd ignores lowercase directives.
  systemd.services.docker = {
    wants = ["mnt-media.mount"];
    after = ["mnt-media.mount"];
  };
  # virtualisation.containers.enable = true;
  # virtualisation = {
  #   podman = {
  #     enable = true;
  #     dockerCompat = true;
  #     defaultNetwork.settings.dns_enabled = true;
  #   };
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.nginx = {
    enable = true;

    # Stream (layer 4 TCP proxy) for SNI-based routing on 443
    streamConfig = ''
      map $ssl_preread_server_name $backend_tls {
        ~\.k8s\.imparham\.in$     127.0.0.1:9443;
        ~\.local\.imparham\.in$   127.0.0.1:7443;
        default                   127.0.0.1:7443;
      }
      server {
        listen 443;
        ssl_preread on;
        proxy_pass $backend_tls;
      }
    '';

    virtualHosts."catchall" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      serverName = "_";
      serverAliases = ["*.imparham.in"];
      onlySSL = false;
      extraConfig = ''
        return 301 https://$host$request_uri;
      '';
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
