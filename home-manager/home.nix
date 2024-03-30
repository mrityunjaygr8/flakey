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
    xsel
    fzf
    less
    difftastic
    lazydocker
    git-credential-manager
    chromium
    devenv
    fd
    ripgrep
    dust
    bottom
    tldr
    neofetch
    go
    python3
    nodePackages.pnpm
    nodePackages.npm
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
  ];


  home.sessionVariables = {
    EDITOR = "nvim";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  };

  services.gpg-agent = {
    enable = true;
  };

  programs = {
    lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            externalDiffCommand = "difft --color=always";
          };
        };
      };
    };
    gpg = {
      enable = true;
    };
    git = {
      enable = true;
      userName = "Mrityunjay Saxena";
      userEmail = "mrityunjaysaxena1996@gmail.com";

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        credential = {
          helper = "store";
        };
      };
    };
    eza = {
      enable = true;
    };
    home-manager = {
      enable = true;
    };
    zoxide = {
      enable = true;
    };
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    bat = {
      enable = true;
      config = {
        theme = "Nord";
      };
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    tmux = {
      enable = true;
      clock24 = true;
      # shortcut = "Space";
      baseIndex = 1;
      escapeTime = 0;
      keyMode = "vi";
      shell = "${pkgs.fish}/bin/fish";
      mouse = true;
      historyLimit = 10000;
      extraConfig = ''
        bind C-l send-keys 'C-l'
        # Smart pane switching with awareness of Vim splits.
        # See: https://github.com/christoomey/vim-tmux-navigator

        # decide whether we're in a Vim process
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
            | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'

        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -n 'C-Space' if-shell "$is_vim" 'send-keys C-Space' 'select-pane -t:.+'

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l
        bind-key -T copy-mode-vi 'C-Space' select-pane -t:.+

        fg="#CBCCC6"
        bg="#212732"
        status_bg="#34455A"
        border_fg="#70748C"
        border_active_fg="#FECB6E"
        status_left_bg="#FFA759"

        set -g status-style "bg=$status_bg,fg=$fg"
        # set -g status-left-style "bg=$status_left_bg,fg=$fg"

        # Border
        set -g pane-border-style "bg=$bg,fg=$border_fg"
        set -g pane-active-border-style "bg=$bg,fg=$border_active_fg"

        # Window
        set -g window-status-current-style "fg=$border_active_fg"
        set -g window-status-style "fg=$fg"
      '';

    };
    fish = {
      enable = true;
      plugins = [
        {
          name = "nix-env";
          src = pkgs.fetchFromGitHub {
            owner = "lilyball";
            repo = "nix-env.fish";
            rev = "00c6cc762427efe08ac0bd0d1b1d12048d3ca727";
            sha256 = "1hrl22dd0aaszdanhvddvqz3aq40jp9zi2zn0v1hjnf7fx4bgpma";
          };
        }
        {
          name = "pure";
          src = pkgs.fetchFromGitHub {
            owner = "pure-fish";
            repo = "pure";
            rev = "a959c8b97d5d444e1e1a04868967276acc127099";
            sha256 = "sha256-6T/4ThQ2KXrSnLBfCHF8PC3rg16D9cCUCvrS8RSvCno=";
          };
        }
        {
          name = "nvm";
          src = pkgs.fetchFromGitHub {
            owner = "jorgebucaran";
            repo = "nvm.fish";
            rev = "9db8eaf6e3064a962bca398edd42162f65058ae8";
            sha256 = "sha256-LkCpij6i5XEkZGYLx9naO/cnbkUCuemypHwTjvfDzuk=";
          };
        }
        {
          name = "virtualfish";
          src = pkgs.fetchFromGitHub {
            owner = "justinmayer";
            repo = "virtualfish";
            rev = "e6163a009cad32feb02a55a631c66d1cc3f22eaa";
            sha256 = "sha256-u6wm+bWCkxxYbtb4wer0AGyVdvuaBiOH1nRmpZssVHo=";
            postFetch = ''
              mkdir $out/conf.d
              mv $out/virtualfish/*.fish $out/conf.d
            '';
          };
        }
        {
          name = "fzf";
          src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "fzf";
            rev = "479fa67d7439b23095e01b64987ae79a91a4e283";
            sha256 = "sha256-28QW/WTLckR4lEfHv6dSotwkAKpNJFCShxmKFGQQ1Ew=";
          };
        }
      ];
      shellInit = ''
        # Set syntax highlighting colours; var names defined here:
        # http://fishshell.com/docs/current/index.html#variables-color
        set fish_color_autosuggestion brblack

        fish_config theme choose "ayu Dark"
        set -Ux GIT_ASKPASS ""
        set VIRTUALFISH_PYTHON_EXEC $(which python)

        set -g direnv_fish_mode disable_arrow

        fish_add_path $HOME/.local/bin

        set -gx EDITOR nvim
        # The WAYLAND_DISPLAY env is not being set in terminals other than GNOME CONSOLE.
        # This was creating a problem when using helix, as it as not using wayland specific 
        # clipboard provider due to this.
        # This function is a workaround for setting the WAYLAND_DISPLAY env
        if not set -q "WAYLAND_DISPLAY"
          if set -q "XDG_SESSION_TYPE"
              echo "XDG_SESSION_TYPE is set"
              set SESSION_TYPE "$XDG_SESSION_TYPE"      

              if test "$SESSION_TYPE" = "wayland"
                  echo "Setting WAYLAND_DISPLAY to 'wayland-0'"
                  set -Ux WAYLAND_DISPLAY "wayland-0"
              else
                  echo "SESSION_TYPE is not 'wayland', exiting"
              end
          else
              echo "XDG_SESSION_TYPE is unset, exiting"
          end
        end
      '';
      shellAliases = {
        rm = "rm -i";
        cp = "cp -i";
        mv = "mv -i";
        mkdir = "mkdir -p";
        tmux = "tmux -u";
        ll = "eza -alhtaccessed";
      };
      shellAbbrs = {
        lg = "lazygit";
        ld = "lazydocker";
        g = "git";
        m = "make";
        n = "nvim";
        o = "open";
        p = "python3";
      };
      functions = {
        mkdcd = {
          description = "Make a directory tree and enter it";
          body = "mkdir -p $argv[1]; and cd $argv[1]";
        };
      };
    };
  };

  home.file = {
    ".config/ghostty/config" = {
      text = ''
        font-family = JetBrainsMonoNL Nerd Font
        font-size = 15
        command = fish
        theme = ayu
      '';
    };
  };

  xdg.configFile = {
    nvim = {
      source = .././config/nvim;
      recursive = true;
    };
  };


  dconf.settings =
    let
      custom_shortcuts =
        let
          inherit (builtins) length head tail listToAttrs genList;
          range = a: b: if a < b then [ a ] ++ range (a + 1) b else [ ];
          globalPath = "org/gnome/settings-daemon/plugins/media-keys";
          path = "${globalPath}/custom-keybindings";
          mkPath = id: "${globalPath}/custom${toString id}";
          isEmpty = list: length list == 0;
          mkSettings = settings:
            let
              checkSettings = { name, command, binding }@this: this;
              aux = i: list:
                if isEmpty list then [ ] else
                let
                  hd = head list;
                  tl = tail list;
                  name = mkPath i;
                in
                aux (i + 1) tl ++ [{
                  name = mkPath i;
                  value = checkSettings hd;
                }];
              settingsList = (aux 0 settings);
            in
            listToAttrs (settingsList ++ [
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
            name = "Launch Ghostty";
            command = "/home/mgr8/.local/bin/ghostty";
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
          toggle-message-tray = [ ];
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          volume-down = [ "<Control><Alt>minus" "XF86AudioLowerVolume" ];
          volume-mute = [ "<Control><Alt>0" "XF86AudioMute" ];
          volume-up = [ "<Control><Alt>equal" "XF86AudioRaiseVolume" ];
        };
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Shift><Super>c" ];
          toggle-maximized = [ "<Super>m" ];
        };
      };

      app_menu_config = {
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };
      };

      extensions = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [ "dash-to-dock@micxgx.gmail.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "gnome-shell-screenshot@ttll.de" "clipboard-indicator@tudmotu.com" "appindicatorsupport@rgcjonas.gmail.com" ];
        };
      };
    in
    lib.mkMerge [ custom_shortcuts wm_keybinds extensions app_menu_config ];

}
