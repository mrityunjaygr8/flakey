# DMS Wallpaper Colors for WezTerm, Fish, and Neovim — Plan

## Goal

Use the palette DMS generates from the current wallpaper across WezTerm, Fish, and Neovim. When DMS changes the palette, refresh the generated app themes without replacing each app's existing configuration or losing a usable fallback.

Keep the integration user-level and declarative. Do not change the Mango, DMS Greeter, GNOME, or Hyprland setup as part of this work.

## Current setup

- DMS writes its generated palette to `~/.cache/DankMaterialShell/dms-colors.json`.
- The file contains `mode`, separate `colors.dark` and `colors.light` palettes, and a `dank16` terminal palette.
- WezTerm is configured in `config/wezterm/wezterm.lua` and currently uses the fixed built-in `Ayu Mirage` scheme. Preserve the GCR `default_ssh_auth_sock` setting while changing its theme.
- Fish's Home Manager `shellInit` runs `fish_config theme choose "ayu Mirage"`; Fish themes are also linked declaratively from `config/fish/themes`.
- Neovim's active theme setup is `config/nvim/plugin/02-colorscheme.lua`, which configures the Ayu plugin in Mirage mode.
- There is no DMS-to-terminal/editor theme synchronization yet.

## Proposed data flow

```text
DMS wallpaper palette JSON
  -> user-level theme generator
     -> generated WezTerm scheme
     -> generated Fish colors/theme
     -> generated Neovim palette/highlights
```

Keep generated artifacts under a dedicated user state/config subdirectory rather than writing into Nix-managed symlinks. The generator should read the DMS JSON, select the active light/dark palette, map semantic colors to each app, and atomically replace its output files.

Use a user-level file watcher or DMS-supported hook to run the generator when `dms-colors.json` changes, plus one initial sync when the graphical session starts. Confirm how DMS writes the file (including atomic rename behavior) before choosing `PathChanged`/`PathModified` or another watcher trigger.

## App integration

### WezTerm

- Generate a TOML color scheme under the user's WezTerm `colors` directory using DMS's `dank16` colors for ANSI slots and the semantic palette for foreground, background, cursor, selection, and tab-bar colors.
- Set `color_scheme` to the generated scheme and ensure WezTerm watches/reloads the generated file when it changes.
- Keep `default_ssh_auth_sock` and all unrelated keybindings/config intact.

### Fish

- Map the DMS palette to Fish syntax highlighting and pager colors.
- Do not edit the Nix-managed Ayu theme file. Prefer a generated theme file or generated Fish snippet in the dedicated sync directory.
- Decide how to update already-running Fish sessions; Fish universal-variable change handlers may be useful, while new shells should load the generated colors automatically.

### Neovim

- Replace or override the active Ayu Mirage palette with DMS-derived highlight groups while preserving syntax/UI groups that are not part of the generated mapping.
- Keep Neovim's current Ayu setup as a fallback if the generated palette is missing or invalid.
- Decide whether running Neovim instances should reload automatically or apply the new palette on next launch, and provide a manual reload command if live updates are unreliable.

## Implementation phases

### 1. Confirm the DMS palette contract

- Inspect representative `dms-colors.json` output after changing wallpapers in both dark and light modes.
- Identify stable fields for ANSI, foreground/background, and semantic colors; do not rely on generated values that are absent in one mode.
- Decide contrast and fallback behavior if DMS has not generated a palette yet.

### 2. Build the generator and watcher

- Add a small user-level generator that validates JSON, maps colors, writes app-specific outputs atomically, and reports malformed or missing input without breaking shell startup.
- Add a user-level watcher/startup sync scoped so it does not run when DMS is not installed or its palette does not exist.
- Avoid polling if a file-change event can be used reliably.

### 3. Integrate each consumer

- Wire WezTerm to the generated scheme and confirm automatic reload.
- Load generated Fish colors for both new and already-running shells without overwriting unrelated universal variables.
- Add a Neovim palette adapter that applies after the base colorscheme and survives `ColorScheme` reloads.
- Ensure all three consumers use the same DMS mode and palette revision.

### 4. Verify wallpaper-driven updates

- Change the wallpaper in DMS and confirm the JSON changes and all three applications update.
- Test dark/light mode changes, missing/corrupt palette fallback, and application startup before the first DMS theme generation.
- Verify syntax contrast, terminal ANSI colors, selection/cursor visibility, Neovim diagnostics/LSP/UI groups, and no regression to SSH-agent behavior.

## Risks and decisions

- DMS palette output is a Material-style theme, while Ayu, Fish, and terminal ANSI schemes have different semantic expectations. Color mapping needs visual review; a direct one-to-one mapping may have poor contrast.
- A file watcher can observe a partial write unless it handles atomic replacement and debounces multiple DMS writes.
- Fish's current theme selection is declared in Home Manager; generated runtime colors must not be overwritten by that startup line.
- WezTerm reloads its config/scheme independently of Fish and Neovim. Each consumer needs a clear update mechanism and fallback.
- Decide whether existing application instances must update live or whether new instances picking up the latest palette is sufficient.

## Resume checklist

1. Read this plan and inspect the current DMS palette plus WezTerm, Fish, and Neovim theme configs.
2. Confirm which DMS JSON fields are stable and define a contrast-checked color mapping.
3. Implement the generator and file-change trigger, then wire each consumer without overwriting Nix-managed files.
4. Test a wallpaper change end-to-end in all three apps and verify fallback behavior before calling the integration complete.
