{
  inputs,
  pkgs,
  ...
}: let
  mangoPackage = inputs.mangowm.packages.${pkgs.stdenv.hostPlatform.system}.mango;
  waybarPackage = pkgs.waybar.overrideAttrs (old: {
    src = inputs.waybar-src;
    mesonFlags = (old.mesonFlags or []) ++ ["-Dmango=true" "-Dwwan=disabled" "-Dcava=disabled"];
  });
  mangoDefaultConfig = pkgs.runCommand "mango-default-config.conf" {} ''
    cp ${mangoPackage}/etc/mango/config.conf "$out"
    substituteInPlace "$out" \
      --replace-fail 'bind=SUPER,o,toggleoverlay,' 'bind=SUPER+CTRL,o,toggleoverlay,' \
      --replace-fail 'bind=SUPER,m,quit' 'bind=SUPER,m,togglemaximizescreen'
    sed -i '/^bind=.*[Aa][Ll][Tt]/d' "$out"
    sed -i '/^mousebind=NONE,btn_middle,togglemaximizescreen,0$/d' "$out"
    sed -i \
      -e '/^bind=CTRL+SHIFT,Left,movewin,-50,+0$/d' \
      -e '/^bind=CTRL+SHIFT,Right,movewin,+50,+0$/d' \
      "$out"
  '';
  windowScreenshot = pkgs.writeShellScriptBin "mango-window-screenshot" ''
    set -euo pipefail
    mkdir -p "$HOME/Pictures/Screenshots"
    geometry=$(${mangoPackage}/bin/mmsg get focusing-client | ${pkgs.jq}/bin/jq -r '"\\(.x),\\(.y) \\(.width)x\\(.height)"')
    [ -z "$geometry" ] && exit 1
    ${pkgs.grim}/bin/grim -g "$geometry" "$HOME/Pictures/Screenshots/$(date +%Y%m%d%H%M%S).png"
  '';
  monitorPower = pkgs.writeShellScriptBin "mango-monitor-power" ''
    set -euo pipefail
    action="''${1:?expected sleep_monitor or wakeup_monitor}"
    case "$action" in
      sleep_monitor|wakeup_monitor) ;;
      *) echo "unsupported monitor action: $action" >&2; exit 2 ;;
    esac

    ${mangoPackage}/bin/mmsg get all-monitors \
      | ${pkgs.jq}/bin/jq -r 'if type == "array" then .[] | .name else .monitors[]? | .name end' \
      | while IFS= read -r monitor; do
          [ -n "$monitor" ] || continue
          ${mangoPackage}/bin/mmsg dispatch "$action,$monitor"
        done
  '';
in {
  imports = [
    inputs.mangowm.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;
    package = mangoPackage;
    topPrefixes = ["source"];
    systemd.variables = [
      "DISPLAY"
      "WAYLAND_DISPLAY"
      "XDG_CURRENT_DESKTOP"
      "XDG_SESSION_TYPE"
      "NIXOS_OZONE_WL"
      "XCURSOR_THEME"
      "XCURSOR_SIZE"
      "MANGO_INSTANCE_SIGNATURE"
    ];
    settings = {
      source = "${mangoDefaultConfig}";
      cursor_theme = "BreezeX-RosePine-Linux";
      cursor_size = 32;
      monitor_rule = [
        "name:^DP-1$,x:0,y:0,scale:1"
        "name:^DP-2$,x:2560,y:0,scale:1,rr:1"
      ];
      bind = [
        "CTRL,space,spawn,sherlock"
        "SUPER,q,killclient"
        "SUPER,v,togglefloating"
        "SUPER,return,spawn,ghostty"
        "SUPER,b,spawn,firefox"
        "SUPER,c,spawn,chromium"
        "SUPER+SHIFT,l,spawn,swaylock"
        "NONE,Print,spawn,${windowScreenshot}/bin/mango-window-screenshot"
        "SUPER+SHIFT,v,spawn,ghostty --class=window.clipse.output -e clipse"
        "SUPER+SHIFT,w,spawn,random-wallpaper"
        "SUPER,h,focusdir,left"
        "SUPER,l,focusdir,right"
        "SUPER,j,focusdir,down"
        "SUPER,k,focusdir,up"
        "SUPER,a,view,1"
        "SUPER+SHIFT,a,tagsilent,1"
        "SUPER+CTRL,a,toggleview,1"
        "SUPER,s,view,2"
        "SUPER+SHIFT,s,tagsilent,2"
        "SUPER+CTRL,s,toggleview,2"
        "SUPER,d,view,3"
        "SUPER+SHIFT,d,tagsilent,3"
        "SUPER+CTRL,d,toggleview,3"
        "SUPER,f,view,4"
        "SUPER+SHIFT,f,tagsilent,4"
        "SUPER+CTRL,f,toggleview,4"
        "SUPER,o,focusmon,next"
        "SUPER+SHIFT,o,tagmon,next,1"
        "SUPER,1,view,1"
        "SUPER+SHIFT,1,tagsilent,1"
        "SUPER,2,view,2"
        "SUPER+SHIFT,2,tagsilent,2"
        "SUPER,3,view,3"
        "SUPER+SHIFT,3,tagsilent,3"
        "SUPER,4,view,4"
        "SUPER+SHIFT,4,tagsilent,4"
        "NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        "NONE,XF86MonBrightnessUp,spawn,brightnessctl -e4 -n2 set 5%+"
        "NONE,XF86MonBrightnessDown,spawn,brightnessctl -e4 -n2 set 5%-"
      ];
      window_rule = [
        "is_floating:1,app_id:window.clipse.output"
      ];
    };
    autostart_sh = "${pkgs.awww}/bin/awww-daemon";
  };

  programs.waybar = {
    enable = true;
    package = waybarPackage;
    systemd = {
      enable = true;
      targets = ["mango-session.target"];
    };
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      modules-left = ["mango/workspaces"];
      modules-center = ["clock"];
      modules-right = ["pulseaudio" "network" "cpu" "memory" "tray"];

      "mango/workspaces" = {
        format = "{icon}";
        "format-icons" = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          active = "●";
          default = "○";
          urgent = "!";
          empty = "·";
        };
        "on-click" = "activate";
        "on-click-right" = "toggle";
      };
      clock = {
        format = "{:%H:%M:%S}";
        "tooltip-format" = "{:%A, %B %d, %Y}";
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        "format-muted" = "muted";
        "format-icons" = {
          default = ["♪"];
        };
      };
      network = {
        "format-wifi" = "Wi-Fi {essid}";
        "format-ethernet" = "Ethernet";
        "format-disconnected" = "Offline";
      };
      cpu.format = "CPU {usage}%";
      memory.format = "RAM {percentage}%";
    };
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "Geist Mono";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: #1e1e2e;
        color: #cdd6f4;
      }

      #workspaces button {
        color: #cdd6f4;
        padding: 0 8px;
      }

      #workspaces button.active {
        color: #89b4fa;
      }

      #clock,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #tray {
        padding: 0 8px;
      }
    '';
  };

  services.swayidle = {
    enable = true;
    systemdTargets = ["mango-session.target"];
    timeouts = [
      {
        timeout = 900;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 1200;
        command = "${monitorPower}/bin/mango-monitor-power sleep_monitor";
        resumeCommand = "${monitorPower}/bin/mango-monitor-power wakeup_monitor";
      }
    ];
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
      lock = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };

  services.wlsunset = {
    enable = true;
    sunrise = "07:30";
    sunset = "20:00";
    systemdTarget = "mango-session.target";
    temperature = {
      day = 6500;
      night = 4500;
    };
  };

  home.packages = with pkgs; [
    rose-pine-cursor
    swaylock
  ];
}
