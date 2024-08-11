# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ../common
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

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
    # start for crafting interpretters
    jetbrains.clion
    jetbrains.idea-ultimate
    kotlin
    # end for crafting interpretters
    kubectl
    kubernetes-helm
    lens
    keypunch
    azure-cli
    beekeeper-studio
    # httpie-desktop
    xsel
    gh
    less
    bruno
    git-credential-manager
    chromium
    devenv
    dust
    bottom
    html-tidy
    nodejs
    vscodium
    bind
    tldr
    neofetch
    jq
    unzip
    toybox
    go
    python3
    pika-backup
    firefox
    nodePackages.pnpm
    nodePackages.npm
    obsidian
    pre-commit
    uget
    postman
    nh
    (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono"];})
  ];

  # programs.wezterm = {
  #   enable = true;
  #   colorSchemes = {
  #     # Bluloco Dark
  #     bluloco_dark = {
  #       foreground = "#b9c0cb";
  #       background = "#282c34";
  #       cursor_bg = "#ffcc00";
  #       cursor_border = "#ffcc00";
  #       cursor_fg = "#282c34";
  #       selection_bg = "#b9c0ca";
  #       selection_fg = "#272b33";
  #
  #       ansi = ["#41444d" "#fc2f52" "#25a45c" "#ff936a" "#3476ff" "#7a82da" "#4483aa" "#cdd4e0"];
  #       brights = ["#8f9aae" "#ff6480" "#3fc56b" "#f9c859" "#10b1fe" "#ff78f8" "#5fb9bc" "#ffffff"];
  #     };
  #   };
  #   extraConfig = ''
  #     return {
  #       font = wezterm.font("Geist Mono"),
  #       font_size = 16.0,
  #       enable_tab_bar = false,
  #       default_prog = {"fish"},
  #       color_scheme = "bluloco_dark",
  #     }
  #   '';
  # };

  programs.alacritty = {
    enable = true;
    settings = {
      shell = "fish";
      font = {
        normal = {
          family = "Geist Mono";
        };
        size = 16.0;
      };
      # Flow colorscheme | Alacritty
      # https://github.com/0xstepit/flow.nvim

      # Black and white
      colors = {
        primary = {
          background = "#1B2228";
          foreground = "#B2C1CC";
        };
        normal = {
          black = "#1D0D0D";
          red = "#F07581";
          green = "#81F075";
          yellow = "#F1E575";
          blue = "#76BDF0";
          magenta = "#A876F0";
          cyan = "#76F0E6";
          white = "#F2F2F2";
        };
      };
      # # Bright colors
      colors.bright = {
        black = "#0D0D0D";
        red = "#F07580";
        green = "#80F075";
        yellow = "#F0E575";
        blue = "#75BDF0";
        magenta = "#A875F0";
        cyan = "#75F0E6";
        white = "#F2F2F2";
      };

      # Search colors
      colors.search.matches = {
        foreground = "#FF007C";
        background = "#0D0D0D";
      };

      colors.search.focused_match = {
        foreground = "#0D0D0D";
        background = "#FF007C";
      };

      # Selection colors
      colors.selection = {
        background = "#FF007C";
        text = "#0D0D0D";
      };

      # Cursors
      # If you don't want to override original behavior, which is nice,
      # remove [colors.cursor] and [colors.vi_mode_cursor].
      colors.cursor = {
        cursor = "#FF007C";
        text = "#0D0D0D";
      };

      colors.vi_mode_cursor = {
        cursor = "#FF007C";
        text = "#0D0D0D";
      };

      colors.footer_bar = {
        foreground = "#FF007C";
        background = "#0D0D0D";
      };

      colors.indexed_colors = [
        {
          index = 93;
          color = "#A875F0";
        }
        {
          index = 198;
          color = "#FF007C";
        }
      ];
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/flakey/scripts"
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
  };

  services.gpg-agent = {
    enable = true;
  };

  programs = {
    home-manager = {
      enable = true;
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
        font-family = Geist Mono
        font-size = 15
        command = fish
        theme = Dracula
      '';
    };
  };

  dconf.settings = let
    custom_shortcuts = let
      inherit (builtins) length head tail listToAttrs genList;
      range = a: b:
        if a < b
        then [a] ++ range (a + 1) b
        else [];
      globalPath = "org/gnome/settings-daemon/plugins/media-keys";
      path = "${globalPath}/custom-keybindings";
      mkPath = id: "${globalPath}/custom${toString id}";
      isEmpty = list: length list == 0;
      mkSettings = settings: let
        checkSettings = {
          name,
          command,
          binding,
        } @ this:
          this;
        aux = i: list:
          if isEmpty list
          then []
          else let
            hd = head list;
            tl = tail list;
            name = mkPath i;
          in
            aux (i + 1) tl
            ++ [
              {
                name = mkPath i;
                value = checkSettings hd;
              }
            ];
        settingsList = aux 0 settings;
      in
        listToAttrs (settingsList
          ++ [
            {
              name = globalPath;
              value = {
                custom-keybindings = genList (i: "/${mkPath i}/") (length settingsList);
              };
            }
          ]);
    in
      mkSettings [
        {
          name = "Launch Terminal";
          command = "alacritty";
          binding = "<Super>Return";
        }
        {
          name = "Launch Firefox";
          command = "firefox";
          binding = "<Super>b";
        }
      ];

    wm_keybinds = {
      "org/gnome/shell/keybindings" = {
        toggle-message-tray = [];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        volume-down = ["<Control><Alt>minus" "XF86AudioLowerVolume"];
        volume-mute = ["<Control><Alt>0" "XF86AudioMute"];
        volume-up = ["<Control><Alt>equal" "XF86AudioRaiseVolume"];
      };
      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Shift><Super>c"];
        toggle-maximized = ["<Super>m"];
      };
    };

    app_menu_config = {
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
      };
    };
  in
    lib.mkMerge [custom_shortcuts wm_keybinds app_menu_config];
}
