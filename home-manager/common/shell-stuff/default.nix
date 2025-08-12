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
    nh
    wl-clipboard
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
        branch = {
          sort = "-committerdate";
        };
        tag = {
          sort = "version:refname";
        };
        push = {
          autoSetupRemote = true;
          followTags = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };
        merge = {
          conflictStyle = "zdiff3";
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
        terraform-ls
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
        bind C-a send-keys 'C-a'

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

        # Name: Flexoki
        # Variant: Dark
        # URL: https://stephango.com/flexoki
        # Description: An inky color scheme for prose and code.
        # Note: Color hexes in lower case to avoid tmux flag confusion

        flexoki_black="#100f0f"
        flexoki_base_950="#1c1b1a"
        flexoki_base_900="#282726"
        flexoki_base_850="#343331"
        flexoki_base_800="#403e3c"
        flexoki_base_700="#575653"
        flexoki_base_600="#6f6e69"
        flexoki_base_500="#878580"
        flexoki_base_300="#b7b5ac"
        flexoki_base_200="#cecdc3"
        flexoki_base_150="#dad8ce"
        flexoki_base_100="#e6e4d9"
        flexoki_base_50="#f2f0e5"
        flexoki_paper="#fffcf0"

        flexoki_red="#af3029"
        flexoki_orange="#bc5215"
        flexoki_yellow="#ad8301"
        flexoki_green="#66800b"
        flexoki_cyan="#24837b"
        flexoki_blue="#205ea6"
        flexoki_purple="#5e409d"
        flexoki_magenta="#a02f6f"

        flexoki_red_2="#d14d41"
        flexoki_orange_2="#da702c"
        flexoki_yellow_2="#d0a215"
        flexoki_green_2="#879a39"
        flexoki_cyan_2="#3aa99f"
        flexoki_blue_2="#4385be"
        flexoki_purple_2="#8b7ec8"
        flexoki_magenta_2="#ce5d97"

        color_tx_1=$flexoki_base_200
        color_tx_2=$flexoki_base_500
        color_tx_3=$flexoki_base_700
        color_bg_1=$flexoki_black
        color_bg_2=$flexoki_base_950
        color_ui_1=$flexoki_base_900
        color_ui_2=$flexoki_base_850
        color_ui_3=$flexoki_base_800

        color_red=$flexoki_red
        color_orange=$flexoki_orange
        color_yellow=$flexoki_yellow
        color_green=$flexoki_green
        color_cyan=$flexoki_cyan
        color_blue=$flexoki_blue
        color_purple=$flexoki_purple
        color_magenta=$flexoki_magenta

        # status
        set -g status "on"
        set -g status-bg $color_bg_2
        set -g status-justify "left"
        set -g status-left-length "100"
        set -g status-right-length "100"

        # messages
        set -g message-style "fg=$color_tx_1,bg=$color_bg_2,align=centre"
        set -g message-command-style "fg=$color_tx_1,bg=$color_ui_2,align=centre"

        # panes
        set -g pane-border-style fg=$color_ui_2
        set -g pane-active-border-style fg=$color_blue

        # windows
        setw -g window-status-activity-style fg=$color_tx_1,bg=$color_bg_1,none
        setw -g window-status-separator ""
        setw -g window-status-style fg=$color_tx_1,bg=$color_bg_1,none

        # statusline
        set -g status-left "#{?client_prefix,#[fg=#$color_bg_1#,bg=#$color_red],#[fg=#$color_bg_1#,bg=#$color_green]}  #S "
        set -g status-right "#[fg=#$color_bg_1,bg=#$color_orange]  #{b:pane_current_path} #[fg=#$color_bg_1,bg=#$color_purple]  %Y-%m-%d %H:%M "

        # window-status
        setw -g window-status-format "#[bg=#$color_bg_2,fg=#$color_tx_2] #I  #W "
        setw -g window-status-current-format "#[bg=#$color_bg_1,fg=#$color_tx_1] #I  #W "

        # Modes
        setw -g clock-mode-colour $color_blue
        setw -g mode-style fg=$color_orange,bg=$color_tx_1,bold


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
            rev = "846f1f20b2d1d0a99e344f250493c41a450f9448";
            sha256 = "sha256-u3qhoYBDZ0zBHbD+arDxLMM8XoLQlNI+S84wnM3nDzg=";
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

        fish_config theme choose "flexoki-dark"
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
        dc = "docker compose";
      };
      functions = {
        mkdcd = {
          description = "Make a directory tree and enter it";
          body = "mkdir -p $argv[1]; and z $argv[1]";
        };
        y = {
          description = "Wrapper for yazi to change CWD when exiting";
          body = ''
            set tmp (mktemp -t "yazi-cwd.XXXXXX")
            yazi $argv --cwd-file="$tmp"
            if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
              builtin cd -- "$cwd"
            end
            rm -f -- "$tmp"
          '';
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
    "fish/themes" = {
      source = ../../../config/fish/themes;
      recursive = true;
    };
  };
}
