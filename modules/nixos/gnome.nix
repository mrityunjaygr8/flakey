{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # SSH agent and GNOME GCR-agent conflict
  # so disabling ssh agent starting where gnome is active
  programs.ssh.startAgent = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    dconf-editor
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.space-bar
    gnomeExtensions.just-perfection
    gnomeExtensions.gnome-40-ui-improvements
    gnomeExtensions.focus-changer
    gnomeExtensions.media-controls
  ];
  services.udev.packages = with pkgs; [gnome-settings-daemon];
  programs.dconf.enable = true;
  programs.dconf.profiles = {
    user.databases = [
      {
        settings = lib.fix (self:
          with lib.gvariant; {
            "org/gnome/shell".enabled-extensions = [
              "appindicatorsupport@rgcjonas.gmail.com"
              "space-bar@luchrioh"
              "Vitals@CoreCoding.com"
              "clipboard-indicator@tudmotu.com"
              "gnome-ui-tune@itstime.tech"
              "focus-changer@heartmire"
              "mediacontrols@cliffniff.github.com"
            ];
            "org/gtk/gtk4/settings/debug".inspector-warning = false;
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-enable-primary-paste = true;
              show-battery-percentage = true;
            };
            "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;
            "org/gnome/desktop/wm/preferences".resize-with-right-button = true;
            "org/gnome/settings-daemon/plugins/power" = {
              power-button-action = "interactive";
              # Suspend only on battery power, not while charging.
              sleep-inactive-ac-type = "nothing";
            };
            "org/gnome/mutter" = {
              dynamic-workspaces = false;
            };
            "org/gnome/desktop/wm/preferences" = {
              num-workspaces = mkInt32 4;
            };
            "org/gtk/gtk4/settings/file-chooser" = {
              show-hidden = true;
              sort-directories-first = true;
              view-type = "list";
            };
            "org/gnome/settings-daemon/plugins/media-keys".home = ["<Super>e"];
            "org/gnome/settings-daemon/plugins/media-keys".screensaver = ["<Super><Shift>o"];
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
              binding = "<Super>Return";
              command = "ghostty";
              name = "Ghostty";
            };
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
              binding = "<Super>b";
              command = "firefox";
              name = "firefox";
            };
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
              binding = "<Super>c";
              command = "chromium";
              name = "Chromium";
            };
            # This is necessary for some reason, or the above custom-keybindings don't work.
            "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
            ];
            "org/gnome/mutter/keybindings" = {
              toggle-tiled-left = ["<Shift><Control><Alt><Super>h"];
              toggle-tiled-right = ["<Shift><Control><Alt><Super>l"];
            };
            "org/gnome/desktop/wm/keybindings" = {
              close = ["<Super>q"];
              panel-run-dialog = ["<Super>BackSpace"];
              move-to-workspace-left = ["<Control><Super>h"];
              move-to-workspace-up = ["<Control><Super>k"];
              move-to-workspace-down = ["<Control><Super>j"];
              move-to-workspace-right = ["<Control><Super>l"];
              move-to-workspace-1 = ["<Control><Super>a"];
              move-to-workspace-2 = ["<Control><Super>s"];
              move-to-workspace-3 = ["<Control><Super>d"];
              move-to-workspace-4 = ["<Control><Super>f"];
              move-to-workspace-last = mkEmptyArray type.string;
              switch-to-workspace-1 = ["<Shift><Super>a"];
              switch-to-workspace-2 = ["<Shift><Super>s"];
              switch-to-workspace-3 = ["<Shift><Super>d"];
              switch-to-workspace-4 = ["<Shift><Super>f"];
              switch-to-workspace-left = ["<Shift><Super>h"];
              switch-to-workspace-up = ["<Shift><Super>k"];
              switch-to-workspace-down = ["<Shift><Super>j"];
              switch-to-workspace-right = ["<Shift><Super>l"];

              move-to-monitor-left = ["<Alt><Super>h"];
              move-to-monitor-up = ["<Alt><Super>k"];
              move-to-monitor-down = ["<Alt><Super>j"];
              move-to-monitor-right = ["<Alt><Super>l"];

              toggle-fullscreen = mkEmptyArray type.string;
              toggle-maximized = ["<Super>m"];
              minimize = mkEmptyArray type.string;
              toggle-on-all-workspaces = ["<Control><Super>w"];
            };
            "org/gnome/shell/keybindings" = {
              # Following binds need to be disabled, as their defaults are used for
              # the binds above, and will run into conflicts.
              switch-to-application-1 = mkEmptyArray type.string;
              switch-to-application-2 = mkEmptyArray type.string;
              switch-to-application-3 = mkEmptyArray type.string;
              switch-to-application-4 = mkEmptyArray type.string;
              switch-to-application-5 = mkEmptyArray type.string;
              switch-to-application-6 = mkEmptyArray type.string;
              switch-to-application-7 = mkEmptyArray type.string;
              switch-to-application-8 = mkEmptyArray type.string;
              switch-to-application-9 = mkEmptyArray type.string;
              open-new-window-application-1 = mkEmptyArray type.string;
              open-new-window-application-2 = mkEmptyArray type.string;
              open-new-window-application-3 = mkEmptyArray type.string;
              open-new-window-application-4 = mkEmptyArray type.string;
              open-new-window-application-5 = mkEmptyArray type.string;
              open-new-window-application-6 = mkEmptyArray type.string;
              open-new-window-application-7 = mkEmptyArray type.string;
              open-new-window-application-8 = mkEmptyArray type.string;
              open-new-window-application-9 = mkEmptyArray type.string;
              toggle-application-view = mkEmptyArray type.string;
              toggle-quick-settings = ["<Super>u"];
              toggle-message-tray = mkEmptyArray type.string;

              screenshot = mkEmptyArray type.string;
              show-screen-recording-ui = mkEmptyArray type.string;
              show-screenshot-ui = ["<Super><Shift>p"];
            };
            "org/gnome/shell".favorite-apps = [
              "com.mitchellh.ghostty.desktop"
              "firefox.desktop"
              "chromium-browser.desktop"
              "postman.desktop"
            ];
          });
      }
    ];
  };
  # programs.dconf.settings = let
  #   custom_shortcuts = let
  #     inherit (builtins) length head tail listToAttrs genList;
  #     range = a: b:
  #       if a < b
  #       then [a] ++ range (a + 1) b
  #       else [];
  #     globalPath = "org/gnome/settings-daemon/plugins/media-keys";
  #     path = "${globalPath}/custom-keybindings";
  #     mkPath = id: "${globalPath}/custom${toString id}";
  #     isEmpty = list: length list == 0;
  #     mkSettings = settings: let
  #       checkSettings = {
  #         name,
  #         command,
  #         binding,
  #       } @ this:
  #         this;
  #       aux = i: list:
  #         if isEmpty list
  #         then []
  #         else let
  #           hd = head list;
  #           tl = tail list;
  #           name = mkPath i;
  #         in
  #           aux (i + 1) tl
  #           ++ [
  #             {
  #               name = mkPath i;
  #               value = checkSettings hd;
  #             }
  #           ];
  #       settingsList = aux 0 settings;
  #     in
  #       listToAttrs (settingsList
  #         ++ [
  #           {
  #             name = globalPath;
  #             value = {
  #               custom-keybindings = genList (i: "/${mkPath i}/") (length settingsList);
  #             };
  #           }
  #         ]);
  #   in
  #     mkSettings [
  #       {
  #         name = "Launch Ghostty";
  #         command = "ghostty";
  #         binding = "<Super>Return";
  #       }
  #       {
  #         name = "Launch Firefox";
  #         command = "firefox";
  #         binding = "<Super>b";
  #       }
  #     ];
  #
  #   wm_keybinds = {
  #     "org/gnome/shell/keybindings" = {
  #       toggle-message-tray = [];
  #     };
  #     "org/gnome/settings-daemon/plugins/media-keys" = {
  #       volume-down = ["<Control><Alt>minus" "XF86AudioLowerVolume"];
  #       volume-mute = ["<Control><Alt>0" "XF86AudioMute"];
  #       volume-up = ["<Control><Alt>equal" "XF86AudioRaiseVolume"];
  #     };
  #     "org/gnome/desktop/wm/keybindings" = {
  #       close = ["<Shift><Super>c"];
  #       toggle-maximized = ["<Super>m"];
  #     };
  #   };
  #
  #   app_menu_config = {
  #     "org/gnome/desktop/wm/preferences" = {
  #       button-layout = "appmenu:minimize,maximize,close";
  #     };
  #   };
  # in
  #   lib.mkMerge [custom_shortcuts wm_keybinds app_menu_config];
}
