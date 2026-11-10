# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  nixpkgs-master,
  ...
}: let
  catppuccin-fish = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "a3b9eb5eaf2171ba1359fe98f20d226c016568cf";
    hash = "sha256-shQxlyoauXJACoZWtRUbRMxmm10R8vOigXwjxBhG8ng=";
  };
  pkgs-master = import nixpkgs-master {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  lspPackages = import ../lsp-packages.nix pkgs;
in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    # inputs.expert.packages."x86_64-linux".default
    ../../../modules/home-manager/k8s-tools.nix
    # ../../../modules/home-manager/omp.nix
  ];

  home.packages = with pkgs;
    [
      firebase-tools
      sops
      age
      ssh-to-age
      difftastic
      nh
      wl-clipboard
      lazydocker
      fd
      ripgrep
      # sesh
      geist-font
      ty
      ruff
      # basedpyright
      gnumake
      inotify-tools
      jq
      postgresql
      zip
    ]
    ++ [pkgs.devenv];

  home.file.".local/bin/wezterm-sesh-preview" = {
    source = ../../../config/wezterm/wezterm-sesh-preview;
    executable = true;
  };

  programs = {
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
    difftastic = {
      enable = true;
      git = {
        enable = true;
        mode = "both";
      };
    };
    lazygit = {
      enable = true;
      settings = {
        git = {
          diffRenderers = [
            {
              type = "extDiff";
              command = "difft --color=always --context={{diffContext}}";
            }
          ];
        };
      };
    };
    gpg = {
      enable = true;
    };
    git = {
      enable = true;
      signing = {
        format = "openpgp";
      };

      settings = {
        user = {
          name = "Mrityunjay Saxena";
          email = "mrityunjaysaxena1996@gmail.com";
        };
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
      withPython3 = true;
      withRuby = false;
      extraPackages = with pkgs;
        [
          ### LSPs start
        ]
        ++ lspPackages
        ++ (with pkgs; [
          vimPlugins.nvim-treesitter-parsers.templ
          prettierd
          stylua
          alejandra
          ### LSPs end
          ### Extra packages Start
          tree-sitter
          websocat
          ### Extra packages End
        ]);
    };
    zellij = {
      enable = true;
      # enableFishIntegration = true;
    };
    herdr = {
      enable = true;
      settings = {
        keys.prefix = "ctrl+a";
        keys.split_vertical = ["prefix+v" "prefix+|"];
        keys.goto = "prefix+s";
        keys.settings = "prefix+shift+s";
        ui.sidebar_start_collapsed = true;
        ui.sidebar_collapsed_mode = "hidden";
        terminal.default_shell = "${lib.getExe pkgs.fish}";
        onboarding = false;
      };
    };
    tmux = {
      enable = true;
      clock24 = true;
      tmuxinator = {
        enable = true;
      };
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
        bind y set-window-option synchronize-panes \; display-message "synchronize-panes is now #{?pane_synchronized,on,off}"
        unbind r
        bind r source-file ~/.config/tmux/tmux.conf
        set -g extended-keys on
        set -g extended-keys-format csi-u

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
        set -g status-right "#{?pane_synchronized,#[bg=red] SYNC ON #[default],} %H:%M %d-%b-%y"
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

        fish_config theme choose "ayu Mirage"
        set -Ux GIT_ASKPASS ""
        set VIRTUALFISH_PYTHON_EXEC $(which python)
        set FLAKE $HOME/flakey

        set -g direnv_fish_mode disable_arrow

        fish_add_path $HOME/.local/bin

        # bind \cs 'sesh connect (sesh list | fzf)'
        bind \cs 'herdr-sesh'

        set DEVENV ${pkgs.devenv}/bin/devenv
        ${pkgs.devenv}/bin/devenv hook fish | source

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
        kg = "KITTY_CONFIG_DIRECTORY=/tmp/opencode/kitty-trial kitty";
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
        herdr-sesh = {
          description = "Fuzzy-attach herdr session/workspace or zoxide dir (sesh replacement)";
          body = ''
            if set -q HERDR_ENV
              set pick (begin; herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | "\(.label)\t\(.workspace_id)"'; zoxide query -l; end | fzf)
              test -z "$pick"; and return
              set id (string split \t -- "$pick")[2]
              if test -n "$id"; and herdr workspace focus "$id" >/dev/null 2>&1
              else if test -d "$pick"
                herdr workspace create --cwd "$pick" --label (basename "$pick") --focus >/dev/null 2>&1
              end
              return
            end
            set pick (begin; herdr session list 2>/dev/null | tail -n +2 | cut -d" " -f1; zoxide query -l; end | fzf)
            test -z "$pick"; and return
            if not test -d "$pick"
              herdr session attach "$pick"
              return
            end
            if herdr workspace create --cwd "$pick" --label (basename "$pick") --focus >/dev/null 2>&1
              herdr
            else
              herdr --session (basename "$pick")
            end
          '';
        };
        wezterm-sesh = {
          description = "Fuzzy-focus a WezTerm pane or create a workspace at a zoxide directory";
          body = ''
            if not set -q WEZTERM_PANE
              echo "wezterm-sesh: run this from a WezTerm pane" >&2
              return 1
            end

            for bin in wezterm jq python3 fzf zoxide
              if not command -q $bin
                echo "wezterm-sesh: '$bin' not found on PATH" >&2
                return 1
              end
            end

            set -l picker_pane $WEZTERM_PANE
            set -l state (wezterm cli list --format json | string collect)
            if test -z "$state"
              echo "wezterm-sesh: couldn't query the WezTerm mux" >&2
              return 1
            end

            # Fields: key<TAB>search/display label<TAB>cwd<TAB>workspace.
            # WezTerm reports cwd as a file:// URL; Python decodes it for display and
            # for exact comparison with zoxide's filesystem paths.
            set -l rows (
              printf '%s' "$state" | python3 -c '
import json, os, re, subprocess, sys
from urllib.parse import unquote, urlparse

ACCENT = "\x1b[38;2;255;180;84m"  # Ayu Mirage amber, matches window_frame
ALERT = "\x1b[38;2;242;135;121m"  # Ayu Mirage red, for unread agent alerts
RESET = "\x1b[0m"

# Agent binaries are nix wrappers, so argv[0] looks like .opencode2-wrapped_ or
# .pi-wrapped rather than the plain command name.
AGENT_RE = re.compile(r"^\.?(opencode\d*|pi|omp|dsh)([-_.][A-Za-z0-9_]*)?$")

def agents_by_tty():
    """pane tty (e.g. pts/8) -> agent name, from the processes on that tty."""
    found = {}
    try:
        out = subprocess.run(
            ["ps", "-eo", "tty=,comm=,args="],
            capture_output=True, text=True, timeout=2,
        ).stdout
    except Exception:
        return found
    for line in out.splitlines():
        parts = line.split(None, 2)
        if len(parts) < 2:
            continue
        tty, comm = parts[0], parts[1]
        argv0 = parts[2].split(None, 1)[0] if len(parts) > 2 else comm
        for cand in (os.path.basename(argv0) or comm, comm):
            match = AGENT_RE.match(cand)
            if match:
                found.setdefault(tty, match.group(1))
    return found

agents = agents_by_tty()
picker = os.environ.get("WEZTERM_PANE", "")
home = os.path.expanduser("~")

ALERT_AGENTS = {
    "opencode_done": "opencode",
    "opencode_permission": "opencode",
    "pi_done": "pi",
}
ALERT_LABELS = {
    "opencode_done": "ready",
    "opencode_permission": "permission",
    "pi_done": "ready",
}

def load_alerts():
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    path = (os.path.join(runtime, "wezterm-agent-alerts.json")
            if runtime else os.path.join(home, ".cache", "wezterm-agent-alerts.json"))
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}

def pid_alive(pid):
    try:
        return int(pid) > 0 and os.path.isdir("/proc/" + str(int(pid)))
    except Exception:
        return False

alerts = load_alerts()
rows = []
for pane in json.load(sys.stdin):
    if str(pane.get("pane_id")) == picker:
        continue
    raw = pane.get("cwd", "")
    parsed = urlparse(raw)
    cwd = unquote(parsed.path) if parsed.scheme == "file" else raw
    shown_cwd = "~" + cwd[len(home):] if cwd == home or cwd.startswith(home + "/") else cwd
    tab = pane.get("tab_title") or "tab " + str(pane.get("tab_id", "?"))
    tty = (pane.get("tty_name") or "").replace("/dev/", "", 1)
    agent = agents.get(tty, "")
    alert = alerts.get(str(pane.get("pane_id")))
    unread = False
    if isinstance(alert, dict) and alert.get("alert") in ALERT_AGENTS:
        pid = alert.get("pid")
        # PID filters out alerts left behind by an agent that has since exited.
        if pid is None or pid_alive(pid):
            unread = bool(agent)
    if unread:
        alert_agent = ALERT_AGENTS[alert.get("alert")]
        status = ALERT_LABELS[alert.get("alert")]
        tag = "{}● {}{} · {}".format(ALERT, alert_agent, RESET, status)
        session = (alert.get("session") or "").replace("\t", " ").replace("\r", " ").replace("\n", " ")
        if session:
            tag += " · " + session
        tag += " · "
    else:
        # Colour just the glyph and agent name; the rest keeps fzf normal colours.
        tag = "{}◆ {}{} · ".format(ACCENT, agent, RESET) if agent else ""
    label = "{} › {} › {} — {}".format(pane.get("workspace", "default"), tab, pane.get("title", "pane"), shown_cwd)
    line = "p:{}\t{}{}\t{}\t{}".format(pane.get("pane_id"), tag, label, cwd, pane.get("workspace", "default"))
    rows.append((0 if unread else 1, len(rows), line))

# Unread agent alerts sort before everything else; preserve pane order otherwise.
for _, _, line in sorted(rows):
    print(line)
'
            )

            set -l open_cwds (printf '%s' "$state" | python3 -c '
import json, sys
from urllib.parse import unquote, urlparse
for pane in json.load(sys.stdin):
    raw = pane.get("cwd", "")
    parsed = urlparse(raw)
    cwd = unquote(parsed.path) if parsed.scheme == "file" else raw
    if cwd:
        print(cwd)
')

            # zoxide query -l is in rank order. Keep the first occurrence, and leave
            # already-open directories represented by their pane rows above.
            set -l seen_dirs
            for dir in (zoxide query -l)
              if contains -- "$dir" $seen_dirs
                continue
              end
              set -a seen_dirs "$dir"
              if test -d "$dir"; and not contains -- "$dir" $open_cwds
                set -l label (string replace -- "$HOME" "~" "$dir")
                set -l workspace (string replace -- "$HOME" "~" "$dir")
                set -a rows (printf 'd:%s\t+ %s (new workspace)\t%s\t%s\n' "$dir" "$label" "$dir" "$workspace")
              end
            end

            if test (count $rows) -eq 0
              echo "wezterm-sesh: no panes or zoxide directories to show" >&2
              wezterm cli kill-pane --pane-id "$picker_pane" >/dev/null 2>&1
              return 0
            end

            # Sort by fzf match score so a contiguous/closer match outranks a
            # scattered one; --tiebreak=index keeps the pane-first, zoxide-rank
            # order (and the untouched order on an empty query) for equal scores.
            set -l pick (printf '%s\n' $rows | fzf \
              --ansi \
              --delimiter='\t' \
              --with-nth=2 \
              --tiebreak=index \
              --reverse \
              --height=100% \
              --prompt='wezterm › ' \
              --preview='wezterm-sesh-preview {1} {3}' \
              --preview-window='right:45%')

            if test -z "$pick"
              wezterm cli kill-pane --pane-id "$picker_pane" >/dev/null 2>&1
              return 0
            end

            set -l fields (string split \t -- "$pick")
            set -l key "$fields[1]"
            set -l target_workspace "$fields[4]"
            set -l target_pane

            if string match -q 'p:*' -- "$key"
              set target_pane (string sub -s 3 -- "$key")
              # The picker is about to visit this pane, so clear its bell marker.
              set -l encoded_pane (printf '%s' "$target_pane" | base64 -w 0)
              printf '\033]1337;SetUserVar=WEZTERM_SESH_CLEAR_ALERT=%s\033\\' "$encoded_pane"
            else
              set -l dir (string sub -s 3 -- "$key")
              # Use the path as the workspace name to avoid basename collisions.
              set target_workspace (string replace -- "$HOME" "~" "$dir")
              set target_pane (wezterm cli spawn --new-window --workspace "$target_workspace" --cwd "$dir" | string trim)
            end

            # Ask the GUI to switch workspaces first; cli activate-pane alone only
            # activates within the currently visible workspace/window.
            set -l encoded_workspace (printf '%s' "$target_workspace" | base64 -w 0)
            printf '\033]1337;SetUserVar=WEZTERM_SESH_WORKSPACE=%s\033\\' "$encoded_workspace"
            sleep 0.15

            if test -n "$target_pane"
              wezterm cli activate-pane --pane-id "$target_pane"
            end
            wezterm cli kill-pane --pane-id "$picker_pane" >/dev/null 2>&1
          '';
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
    "wezterm/wezterm.lua" = {
      source = ../../../config/wezterm/wezterm.lua;
    };
    # sesh = {
    #   source = ../../../config/sesh;
    #   recursive = true;
    # };
    "fish/themes/Catppuccin Mocha.theme" = {
      source = "${catppuccin-fish}/themes/Catppuccin Mocha.theme";
    };
    "fish/themes" = {
      source = ../../../config/fish/themes;
      recursive = true;
    };
  };
}
