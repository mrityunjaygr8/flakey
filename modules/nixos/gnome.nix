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
  programs.dconf.profiles = {
    user.databases = [
      {
        settings = {
          "org/gnome/shell".enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            # "pano@elhan.io"
            "space-bar@luchrioh"
            "Vitals@CoreCoding.com"
          ];
        };
      }
    ];
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
          name = "Launch Ghostty";
          command = "ghostty";
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
