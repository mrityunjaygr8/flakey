{
  inputs,
  pkgs,
  config,
  ...
}: let
  # --- Tag / workspace indicator shared by both Hyprland and river sessions.
  # The compositor is chosen at login (GDM), so this adapts at runtime:
  # it reads state via `hyprctl` when Hyprland is running and via
  # `riverctl` otherwise.
  stateScript = pkgs.writeShellScriptBin "wayle-workspaces" ''
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      active="$("${pkgs.hyprland}/bin/hyprctl" activeworkspace -j 2>/dev/null | "${pkgs.jq}/bin/jq" -r '.id' || true)"
      ids="$("${pkgs.hyprland}/bin/hyprctl" workspaces -j 2>/dev/null | "${pkgs.jq}/bin/jq" -r '.[].id' 2>/dev/null | sort -n | uniq || true)"
      out=""
      for w in $ids; do
        if [ "$w" = "$active" ]; then
          out="$out ($w)"
        else
          out="$out $w"
        fi
      done
      printf '%s\n' "''${out# }"
    else
      focused="$("${pkgs.river}/bin/riverctl" get-focused-tags 2>/dev/null || echo 0)"
      view="$("${pkgs.river}/bin/riverctl" get-view-tags 2>/dev/null || echo 0)"
      out=""
      for i in 1 2 3 4; do
        bit=$((1 << (i - 1)))
        if [ $((view & bit)) -ne 0 ]; then
          if [ $((focused & bit)) -ne 0 ]; then
            out="$out ($i)"
          else
            out="$out $i"
          fi
        else
          out="$out ·"
        fi
      done
      printf '%s\n' "''${out# }"
    fi
  '';

  # cycle $1=mask $2=step : set focused tags to the next/prev single tag.
  cycle = ''
    local f="$1" step="$2" cur=1 next i bit
    for i in 1 2 3 4; do
      if [ $(((1 << (i - 1)) & f)) -ne 0 ]; then cur=$i; break; fi
    done
    next=$((cur + step))
    if [ "$next" -lt 1 ]; then next=4; fi
    if [ "$next" -gt 4 ]; then next=1; fi
    "${pkgs.river}/bin/riverctl" set-focused-tags $((1 << (next - 1)))
  '';

  actionScript = pkgs.writeShellScriptBin "wayle-workspace-action" ''
    #!/usr/bin/env bash
    set -euo pipefail
    action="''${1:-}"
    if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      case "$action" in
        left-click)
          "${pkgs.hyprland}/bin/hyprctl" dispatch workspace name:"$("${pkgs.hyprland}/bin/hyprctl" activeworkspace -j | "${pkgs.jq}/bin/jq" -r '.id')"
          ;;
        scroll-up)
          "${pkgs.hyprland}/bin/hyprctl" dispatch workspace +1
          ;;
        scroll-down)
          "${pkgs.hyprland}/bin/hyprctl" dispatch workspace -1
          ;;
      esac
    else
      focused="$("${pkgs.river}/bin/riverctl" get-focused-tags 2>/dev/null || echo 1)"
      case "$action" in
        left-click)
          "${pkgs.river}/bin/riverctl" set-focused-tags "$focused"
          ;;
        scroll-up)
          ${cycle}
          cycle "$focused" 1
          ;;
        scroll-down)
          ${cycle}
          cycle "$focused" -1
          ;;
      esac
    fi
  '';
in {
  # Register the workspace indicator as a wayle custom module (poll mode,
  # ~2Hz). Rendered by referencing `custom-workspaces` in the bar layout.
  services.wayle.settings.modules.custom = [
    {
      id = "workspaces";
      mode = "poll";
      interval-ms = 500;
      format = "{{ output }}";
      command = "${stateScript}/bin/wayle-workspaces";
      left-click = "${actionScript}/bin/wayle-workspace-action left-click";
      scroll-up = "${actionScript}/bin/wayle-workspace-action scroll-up";
      scroll-down = "${actionScript}/bin/wayle-workspace-action scroll-down";
      on-action = "${stateScript}/bin/wayle-workspaces";
    }
  ];
}
