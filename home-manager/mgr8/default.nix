# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # opencodePackage = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # patchedOpencodePackage = opencodePackage.overrideAttrs (old: {
  #   preBuild =
  #     (old.preBuild or "")
  #     + ''
  #       mkdir -p .github
  #       cp ${inputs.opencode}/.github/TEAM_MEMBERS .github/TEAM_MEMBERS
  #     '';
  # });
in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ../common
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/opencode.nix
    ../../modules/home-manager/sops.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  # TODO: Set your username
  home = {
    username = "mgr8";
    homeDirectory = "/home/mgr8";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    iloader
    # jetbrains.idea-community-bin
    typst
    beamMinimal28Packages.elixir
    bottom
    calibre
    # (pkgs.callPackage ./../../pkgs/calibre {})
    awscli2
    bun
    obsidian
    xan
    tesseract
    ghostty
    restic
    nmap
    kazam
    atkinson-hyperlegible
    onlyoffice-desktopeditors
    # code-cursor
    ares-cli
    # opencode
    uv
    trivy
    pgadmin4-desktopmode
    shellcheck
    posting
    git-crypt
    # ollama
    # start for crafting interpretters
    # jetbrains.clion
    # jetbrains.idea-ultimate
    # kotlin
    # end for crafting interpretters
    kubectl
    ibmcloud-cli
    kubernetes-helm
    azure-cli
    # beekeeper-studio
    opentofu
    # httpie-desktop
    xsel
    gh
    less
    bruno
    git-credential-manager
    dust
    bottom
    html-tidy
    nodejs
    vscodium
    bind
    fastfetch
    # zed-editor
    jq
    unzip
    go
    # pika-backup
    firefox
    # pnpm_8
    yarn
    # pnpm_9
    pnpm_10
    # nodePackages.npm
    pre-commit
    uget
    postman
    nh
    yazi
    nerd-fonts.fira-code
    nerd-fonts.terminess-ttf
    nerd-fonts.gohufont
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono
    nerd-fonts._0xproto
    nerd-fonts.lilex
    ioskeley-mono.normal-term-NF
    monaspace
  ];

  programs.zed-editor = {
    enable = true;
    # extenstions = ["nix"];
    userKeymaps = [
      {
        "context" = "Workspace";
        "bindings" = {
          "space w" = "workspace::Save";
          "space q a" = "pane::CloseAllItems";
          "space q b" = "pane::CloseActiveItem";
        };
      }
    ];
    userSettings = {
      "vim_mode" = true;
      "ui_font_size" = 16;
      "buffer_font_size" = 16;
      "theme" = {
        "mode" = "system";
        "light" = "One Light";
        "dark" = "Snowflake Original";
      };
      "terminal" = {
        "shell" = {"program" = "fish";};
        "detect_venv" = {
          "on" = {
            "directories" = [".venv" "venv"];
            "activate_script" = "fish";
          };
        };
      };
      "ui_font_family" = "Geist Mono";
    };
  };

  # programs.opencode = {
  #   enable = true;
  #   # package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
  #   #   inherit (pkgs) bun;
  #   # };
  #   package = (inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default.override
  #     {
  #       inherit (pkgs) bun;
  #     }).overrideAttrs (old: {
  #     preBuild =
  #       (old.preBuild or "")
  #       + ''
  #         substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
  #           --replace-fail 'const prettier = await import("prettier")' 'const prettier: any = { format: async (s: string) => s }' \
  #           --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
  #           --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
  #       '';
  #   });
  # };
  programs.chromium = {
    enable = true;
    commandLineArgs = ["--enable-features=UseOzonePlatform" "--ozone-platform=wayland"];
  };

  programs.alacritty = {
    enable = true;
    settings = {
      terminal = {
        shell = "fish";
      };
      font = {
        normal = {
          family = "Geist Mono";
        };
        size = 16.0;
      };
      env = {
        TERM = "xterm-256color";
      };
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          dim_foreground = "#7f849c";
          bright_foreground = "#cdd6f4";
        };
        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };
        vi_mode_cursor = {
          text = "#1e1e2e";
          cursor = "#b4befe";
        };
        search = {
          matches = {
            foreground = "#1e1e2e";
            background = "#a6adc8";
          };
          focused_match = {
            foreground = "#1e1e2e";
            background = "#a6e3a1";
          };
        };
        footer_bar = {
          foreground = "#1e1e2e";
          background = "#a6adc8";
        };
        hints = {
          start = {
            foreground = "#1e1e2e";
            background = "#f9e2af";
          };
          end = {
            foreground = "#1e1e2e";
            background = "#a6adc8";
          };
        };
        selection = {
          text = "#1e1e2e";
          background = "#f5e0dc";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
        dim = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        indexed_colors = [
          {
            index = 16;
            color = "#fab387";
          }
          {
            index = 17;
            color = "#f5e0dc";
          }
        ];
      };
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/flakey/scripts"
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # services.gpg-agent = {
  #   enable = true;
  # };

  programs = {
    home-manager = {
      enable = true;
    };
    tealdeer = {
      enable = true;
      settings = {
        update = {
          auto_update = false;
        };
      };
    };
    gh-dash = {
      enable = true;
      settings = {
        repoPaths = {
          "egyanamtech/vlcm_fetcher" = "~/stuff/vlcm/vlcm_fetcher/";
          "egyanamtech/vlcm_backend" = "~/stuff/vlcm/vlcm_fetcher/vlcm_backend";
          "egyanamtech/vlcm_frontend_react" = "~/stuff/vlcm/vlcm_fetcher/vlcm_frontend";
        };
      };
    };
  };

  home.file = {
    ".config/ghostty/config" = {
      text = ''
        font-family = IoskeleyMonoTerm Nerd Font
        # font-family = Geist Mono
        # font-family = Terminess Nerd Font Mono
        # font-family = Monaspace Krypton Frozen
        # font-family = Lilex Nerd Font
        # font-family = 0xProto Nerd Font Mono
        font-size = 16
        command = fish
        theme = Ayu Mirage
      '';
    };
  };
}
