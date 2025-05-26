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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
    # gnomeExtensions.pano
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.space-bar
    gnomeExtensions.just-perfection
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
              # "pano@elhan.io"
              "space-bar@luchrioh"
              "Vitals@CoreCoding.com"
            ];
            "org/gtk/gtk4/settings/debug".inspector-warning = false;
            "org/gnome/desktop/calendar".show-weekdate = true;
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-enable-primary-paste = false;
              gtk-theme = "adw-gtk3-dark";
              icon-theme = "MoreWaita";
              monospace-font-name = "Recursive 10 @MONO=1,CRSV=0,wght=400";
              show-battery-percentage = true;
            };
            "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;
            "org/gnome/desktop/wm/preferences".resize-with-right-button = true;
            "org/gnome/settings-daemon/plugins/power" = {
              power-button-action = "interactive";
              # Suspend only on battery power, not while charging.
              sleep-inactive-ac-type = "nothing";
            };
            "org/gtk/gtk4/settings/file-chooser" = {
              show-hidden = true;
              sort-directories-first = true;
              view-type = "list";
            };
            "org/gnome/settings-daemon/plugins/media-keys".home = ["<Super>e"];
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
            ];
            "org/gnome/desktop/wm/keybindings" = {
              close = ["<Super>q"];
              move-to-workspace-left = ["<Control><Super>l"];
              move-to-workspace-right = ["<Control><Super>h"];
              panel-run-dialog = ["spacer"];
              switch-to-workspace-1 = ["<Shift><Super>1"];
              switch-to-workspace-2 = ["<Shift><Super>2"];
              switch-to-workspace-3 = ["<Shift><Super>3"];
              switch-to-workspace-4 = ["<Shift><Super>4"];
              switch-to-workspace-left = ["<Super>l"];
              switch-to-workspace-right = ["<Super>h"];
              toggle-fullscreen = ["<Shift><Super>f"];
              toggle-maximized = ["<Super>f"];
              toggle-on-all-workspaces = ["<Control><Super>s"];
            };
            "org/gnome/shell/keybindings" = {
              # Following binds need to be disabled, as their defaults are used for
              # the binds above, and will run into conflicts.
              switch-to-application-1 = mkEmptyArray type.string;
              switch-to-application-2 = mkEmptyArray type.string;
              switch-to-application-3 = mkEmptyArray type.string;
              switch-to-application-4 = mkEmptyArray type.string;
              toggle-application-view = mkEmptyArray type.string;
              toggle-quick-settings = mkEmptyArray type.string;

              screenshot = mkEmptyArray type.string;
              show-screen-recording-ui = ["<Shift><Super>r"];
              show-screenshot-ui = ["<Shift><Super>s"];
            };
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
