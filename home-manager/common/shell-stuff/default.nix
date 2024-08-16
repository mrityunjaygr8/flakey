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
  catppuccin-fish = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "a3b9eb5eaf2171ba1359fe98f20d226c016568cf";
    hash = "sha256-shQxlyoauXJACoZWtRUbRMxmm10R8vOigXwjxBhG8ng=";
  };
in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  home.packages = with pkgs; [
    difftastic
    lazydocker
    fd
    ripgrep
    sesh
    geist-font
  ];

  programs = {
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
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
      extraPackages = with pkgs; [
        ### LSPs start
        lua-language-server
        nodePackages.typescript-language-server
        nodePackages.bash-language-server
        vimPlugins.nvim-treesitter-parsers.templ
        pyright
        gopls
        prettierd
        ruff
        stylua
        nixd
        alejandra
        ### LSPs end
      ];
    };
    tmux = {
      enable = true;
      clock24 = true;
      prefix = "C-a";
      baseIndex = 1;
      sensibleOnTop = false;
      escapeTime = 0;
      keyMode = "vi";
      shell = "${pkgs.fish}/bin/fish";
      mouse = true;
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.catppuccin;

          extraConfig = ''
            set -g @catppuccin_flavor 'mocha'
            set -g @catppuccin_window_default_fill "number"

            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#{pane_current_path}"

            set -g @catppuccin_status_modules_right "application session date_time"
            set -g @catppuccin_status_left_separator  "█"
            set -g @catppuccin_status_right_separator "█"
          '';
        }
      ];
      terminal = "tmux-256color";
      historyLimit = 10000;
      extraConfig = ''
        set -ag terminal-overrides ",xterm-256color:RGB"

        unbind %
        bind | split-window -h

        unbind '"'
        bind - split-window -v
        bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
        bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"
        unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode after dragging with mouse

        unbind r
        bind r source-file ~/.config/tmux/tmux.conf

        bind x kill-pane
        set -g detach-on-destroy off
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
        {
          name = "catpuccin";
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "fish";
            rev = "a3b9eb5eaf2171ba1359fe98f20d226c016568cf";
            sha256 = "sha256-shQxlyoauXJACoZWtRUbRMxmm10R8vOigXwjxBhG8ng=";
          };
        }
      ];
      shellInit = ''
        # Set syntax highlighting colours; var names defined here:
        # http://fishshell.com/docs/current/index.html#variables-color
        set fish_color_autosuggestion brblack

        fish_config theme choose "Catppuccin Mocha"
        set -Ux GIT_ASKPASS ""
        set VIRTUALFISH_PYTHON_EXEC $(which python)
        set FLAKE $HOME/flakey

        set -g direnv_fish_mode disable_arrow

        fish_add_path $HOME/.local/bin

        bind \cs 'sesh connect (sesh list | fzf)'

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
        docker-compose = "docker compose";
      };
      shellAbbrs = {
        k = "kubectl";
        lg = "lazygit";
        ld = "lazydocker";
        g = "git";
        m = "make";
        n = "nvim";
        o = "open";
        p = "python3";
        nod = "nh os switch --dry $HOME/flakey";
        no = "nh os switch $HOME/flakey";
        nud = "nh home switch --dry $HOME/flakey";
        nu = "nh home switch $HOME/flakey";
      };
      functions = {
        mkdcd = {
          description = "Make a directory tree and enter it";
          body = "mkdir -p $argv[1]; and cd $argv[1]";
        };
      };
    };
  };

  xdg.configFile = {
    nvim = {
      source = ../../../config/nvim;
      recursive = true;
    };
    sesh = {
      source = ../../../config/sesh;
      recursive = true;
    };
    "fish/themes/Catppuccin Mocha.theme" = {
      source = "${catppuccin-fish}/themes/Catppuccin Mocha.theme";
    };
  };
}
