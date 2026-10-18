{mango}:
mango.overrideAttrs (old: {
  postPatch =
    (old.postPatch or "")
    + ''
      substituteInPlace src/config/option_defs.c \
        --replace-fail 'strcmp(key, "border_color") == 0' 'strcmp(key, "border_color") == 0 || strcmp(key, "bordercolor") == 0' \
        --replace-fail 'strcmp(key, "focus_color") == 0' 'strcmp(key, "focus_color") == 0 || strcmp(key, "focuscolor") == 0' \
        --replace-fail 'strcmp(key, "urgent_color") == 0' 'strcmp(key, "urgent_color") == 0 || strcmp(key, "urgentcolor") == 0' \
        --replace-fail 'strcmp(key, "border_px") == 0' 'strcmp(key, "border_px") == 0 || strcmp(key, "borderpx") == 0' \
        --replace-fail 'strcmp(key, "gap_inner_horizontal") == 0' 'strcmp(key, "gap_inner_horizontal") == 0 || strcmp(key, "gappih") == 0' \
        --replace-fail 'strcmp(key, "gap_inner_vertical") == 0' 'strcmp(key, "gap_inner_vertical") == 0 || strcmp(key, "gappiv") == 0' \
        --replace-fail 'strcmp(key, "gap_outer_horizontal") == 0' 'strcmp(key, "gap_outer_horizontal") == 0 || strcmp(key, "gappoh") == 0' \
        --replace-fail 'strcmp(key, "gap_outer_vertical") == 0' 'strcmp(key, "gap_outer_vertical") == 0 || strcmp(key, "gappov") == 0'
    '';
})
