# Desktop Environment Plans

This file consolidates nine related-but-independent workstreams: WezTerm project layout restoration, the DMS screenshot picker, DMS wallpaper colors for terminal/editor applications, Mango overview/layout visibility, WezTerm scrollback copy mode, Mango window/layer blur, Firefox chrome (rounded design + DMS theming), keyboard/keybind ergonomics, and declarative DMS configuration. Keep their implementation and verification separate, and preserve the shared constraints below.

## Shared constraints

- Preserve current Mango, DMS, GNOME, and Hyprland behavior unless a workstream explicitly needs to change it.
- Keep generated/runtime data separate from declarative source files; do not overwrite Home Manager-managed files with runtime generators.
- The WezTerm project-layout, wallpaper-color, and Mango/WezTerm key-collision work all touch `config/wezterm/wezterm.lua`; coordinate edits and preserve the GCR `default_ssh_auth_sock` configuration.
- The DMS wallpaper-color work, Firefox chrome theming, and any generated theme snippets share one palette source (`~/.cache/DankMaterialShell/dms-colors.json`); build/extend a single generator rather than per-app ad-hoc scripts.
- Firefox is a Home Manager package only (no declarative profile today). Prefer the least-invasive way to add chrome CSS/prefs without creating a second profile or disturbing the existing logins/bookmarks.
- DMS configuration splits into declarative inputs (`programs.dank-material-shell.settings`/`session`/`clipboardSettings`/plugin settings) and runtime-generated outputs (`dms-colors.json`, `firefox.css`, Mango `dms/*.conf`). Manage only the former in Nix; never capture the generated outputs.

---

## 1. WezTerm Project Layout Restore

### Goal

Complete G7 of the terminal/multiplexer evaluation: recreate selected project workspaces, tabs, panes, and working directories after a fresh WezTerm start or reboot. Commands are relaunched; live processes do not survive a restart.

Keep this as a user-level trial. Do not wire it through Nix/Home Manager unless requested.

### Current setup

- WezTerm `0-unstable-2026-09-29`, configured at `~/.config/wezterm/wezterm.lua`.
- Fish picker: `~/.config/fish/functions/wezterm-sesh.fish`, invoked with `Ctrl+Shift+S`.
- The picker lists existing panes plus ranked zoxide directories and can create a generic workspace at a selected directory.
- The picker and GUI communicate through a WezTerm user variable; the GUI switches workspace and focuses the selected pane.
- Current observed `vlcm_fetcher` workspace:
  - One tab with panes at the project root, `vlcm_backend/src`, and `vlcm_frontend`.
  - A second tab at `vlcm_frontend/demo_files`.
  - These panes were running Fish when inspected; confirm which commands should be relaunched.
- `vlcm_backend` may be a nested project with its own layout; decide whether it gets an independent workspace.
- G6 (survival of GUI closure) is not important to the user; focus on layout/cwd restoration.

### Built-in support vs. custom manifest

WezTerm provides the startup hooks and mux APIs, but does **not** have a native project manifest or automatic project-layout save/restore format. Define a small data-only JSON manifest and loader in the user-level WezTerm config.

- `gui-startup` runs once when a fresh GUI server starts via `wezterm start` and can create workspaces/layouts.
- `wezterm.mux.spawn_window` creates a MuxWindow in a workspace.
- `MuxWindow:spawn_tab` creates tabs; `Pane:split` creates panes with a direction, size, cwd, and command; `MuxTab:set_title` sets tab names.
- If startup code creates panes, those take precedence over WezTerm's default-program spawn.

References:
- https://wezterm.org/config/lua/gui-events/gui-startup.html
- https://wezterm.org/config/lua/mux-window/spawn_tab.html
- https://wezterm.org/config/lua/pane/split.html
- https://wezterm.org/recipes/workspaces.html

### Proposed project manifest

Store one manifest in each project, for example:

```text
<project-root>/.wezterm/session.json
```

Example shape:

```json
{
  "workspace": "vlcm_fetcher",
  "root": "..",
  "restore_on_start": true,
  "tabs": [
    {
      "title": "Backend",
      "layout": {
        "direction": "Right",
        "size": 0.35,
        "first": { "cwd": "vlcm_backend/src", "command": ["fish", "-l"] },
        "second": {
          "direction": "Bottom",
          "size": 0.5,
          "first": { "cwd": "vlcm_backend", "command": ["fish", "-l"] },
          "second": { "cwd": "vlcm_frontend", "command": ["fish", "-l"] }
        }
      }
    },
    {
      "title": "Demo files",
      "layout": { "cwd": "vlcm_frontend/demo_files", "command": ["fish", "-l"] }
    }
  ]
}
```

In this example the manifest is at `<project-root>/.wezterm/session.json`, so `root: ".."` points to the project root. Resolve it relative to the manifest's directory at runtime; the manifest contains no machine-specific absolute project path.

Manifest rules:

- `workspace` is the session-like workspace name.
- `root` is relative to the manifest's directory (normally `..`); relative `cwd` values resolve against the resulting project root. Do not store machine-specific absolute roots in project manifests.
- `restore_on_start` opts the project into automatic startup restoration.
- Each `tabs` entry is a tmux-window-like tab. A layout leaf describes a pane; a split node has `direction`, optional `size`, and `first`/`second` children.
- `command` is optional; omitted commands use WezTerm's Fish `default_prog`.
- The manifest is data, not executable project Lua.

The example mirrors observed cwd locations only. Confirm the actual layout, tab names, and commands before using it.

### Nested-project behavior

1. When the picker selects a directory, search upward for `.wezterm/session.json`.
2. If manifests are nested, the nearest/deepest project root wins: selecting `vlcm_backend` uses its manifest; selecting `vlcm_fetcher` uses the parent's.
3. Do not merge parent and child manifests implicitly. A parent layout may intentionally open a pane inside a child repo, but that does not create the child's separate workspace.
4. A small user-level registry in `~/.config/wezterm/wezterm.lua` lists known manifests for startup restoration; WezTerm will not discover all zoxide directories on its own.
5. Restore only registered manifests with `restore_on_start = true`. If both parent and child are restored, they become separate workspaces; avoid duplicate views by choosing their flags/layouts intentionally.
6. If no manifest exists, preserve the current generic one-tab workspace fallback.

### Implementation phases

#### 1. Confirm the first layout

- Inspect the `vlcm_fetcher` and `vlcm_backend` repository roots.
- Decide whether `vlcm_backend` is an independent project workspace or just part of the parent layout.
- Confirm tab titles, pane geometry, cwd values, launch commands, and which projects should restore automatically.

#### 2. Implement the manifest loader

- Add manifest reading, validation, and path resolution to `~/.config/wezterm/wezterm.lua`. Resolve the manifest's own location first, then its relative `root`, then each relative pane `cwd` against that project root.
- Implement one `apply_project_manifest(manifest)` routine using `wezterm.mux.spawn_window`, `window:spawn_tab`, and recursive `pane:split` calls.
- Set workspace and tab names; validate missing directories/commands and log clear errors.
- Ensure applying an existing workspace focuses it without creating duplicate tabs.

#### 3. Connect the fzf picker

- Extend `wezterm-sesh.fish` directory selection to find the nearest manifest and pass its path to the WezTerm GUI using a distinct user-variable request.
- The GUI applies the manifest if the workspace is absent; if already present, it only activates it.
- Keep the existing generic-directory fallback for folders without manifests.

#### 4. Add startup restoration

- In `gui-startup`, load registered manifests marked `restore_on_start = true` and construct each workspace once.
- Select a configured default workspace after creation.
- Respect explicit `wezterm start` commands rather than unexpectedly replacing them.

#### 5. Verify G7

- Validate Lua with `wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua`.
- Test picker behavior for an existing workspace, a new project with a manifest, a nested manifest, and a folder without one.
- Perform a fresh WezTerm GUI start and compare `wezterm cli list --format json` against the expected workspace/tab/pane/cwd/title layout.
- Confirm commands restart in their configured cwd. Only mark G7 complete after this round trip passes.
- Then complete the WezTerm evaluation scorecard.

### Risks and decisions

- `gui-startup` runs for a fresh GUI server, not when connecting to an existing GUI.
- This recreates layout/cwd/commands; it does not preserve running processes. G6 remains out of scope unless the user changes priority.
- Decide whether manifests should be committed into each project or kept user-local. The proposal is project-local manifests plus a user-local startup registry.
- No Nix/Home Manager changes are planned for this workstream.

---

## 2. DMS Screenshot Picker

### Goal

Polish the custom Quickshell screenshot picker so it looks and behaves like part of DMS, while making multi-monitor region capture predictable. Keep `Print` as the entry point and continue using DMS screenshot functionality wherever it supports the requested capture mode.

### Current setup

- Mango `Print` opens `config/quickshell/screenshot-picker.qml` through a standalone Quickshell process.
- The picker currently has two steps:
  1. Choose region, focused window, focused output, all outputs, DP-1, or DP-2.
  2. Choose file + clipboard, file only, or clipboard only.
- The picker uses a custom dark palette, not DMS's active theme colors or shared components.
- The `Region` option calls `dms screenshot`. DMS's region selector spans the combined desktop and presents selection surfaces on both outputs.
- DMS documents `-o/--output` for the `output` capture mode, but not as a constraint for region mode. The picker therefore cannot currently limit a region selection to one monitor.
- The implementation is in `config/quickshell/screenshot-picker.qml` and `modules/home-manager/mango.nix`.

### Known issue: picker is too slow and captures itself

- Selecting an option is slow to take effect, and by the time `dms screenshot` runs the picker overlay is still on screen — so the captured image is of the **picker itself** instead of the intended window/region/output.
- Root cause hypotheses: the Quickshell overlay dismisses with an exit animation and/or is not destroyed/unmapped before the capture command is spawned, so the compositor still composites it into the frame.
- Two acceptable fixes (pick one, or combine):
  1. **Dismiss with no animation** — hide/destroy the picker surface immediately (skip or shorten the exit animation) and wait until the surface is actually unmapped (e.g. one compositor frame / a short fixed delay after the hide call) before invoking the capture.
  2. **Countdown timer** — after the selection, wait ~2–3 seconds before capturing, optionally showing a small non-captured countdown indicator outside the captured area (or no indicator at all).
- Either way, the capture must not include any picker/countdown UI.

### Design goals

- Match DMS visual language: active theme colors, typography, corner radius, spacing, and focus/hover treatments.
- Keep the interaction fast and keyboard friendly: launch on `Print`, navigate with keyboard, use `Enter` to select, and `Escape` to go back or dismiss.
- Make the capture target and destination explicit before starting the screenshot.
- Clearly distinguish a region across the whole desktop from a region limited to one output.
- Never capture the picker itself: the overlay must be fully gone (or the capture delayed past it) before `dms screenshot` runs.
- Feel responsive: minimize the delay between choosing an option and the capture starting (avoid a perceptibly slow dismiss).
- Preserve the supported DMS capture modes for window, focused output, all outputs, and named outputs.

### Region behavior to resolve

1. Check whether DMS has a supported API or CLI option to constrain its region selector to a named output.
2. If it does, add `Region on DP-1` and `Region on DP-2` to the picker and use that supported DMS path.
3. If it does not, prototype an output-constrained Quickshell selection overlay. Reuse DMS's capture backend if practical; otherwise use a small, explicit fallback for the selected region rather than unexpectedly selecting across both outputs.
4. Decide whether to retain a separate `Region across all outputs` choice. Do not silently change the meaning of the existing `Region` option.

### Implementation phases

#### 1. Inspect DMS theme integration

- Determine whether the picker can import DMS shared QML components or should read the active DMS-generated theme colors.
- Avoid duplicating a large portion of DMS's internal UI or depending on unstable private component paths without a clear reason.
- Define a small fallback palette for cases where DMS theme data is unavailable.

#### 2. Refine the picker UI

- Group choices visually into capture target and output destination.
- Add clear descriptions and selected/focused states; preserve the current concise two-step flow unless a single-screen layout is demonstrably clearer.
- Ensure keyboard focus starts on a sensible option, moves predictably through all choices, and returns to the right control on `Escape`/Back.
- Ensure clicking outside or pressing `Escape` cancels without capturing.
- Keep the overlay on the appropriate monitor and avoid blocking other displays unnecessarily.

#### 3. Implement explicit per-output region capture

- Add output-specific region choices after resolving the DMS capability above.
- Preserve `Window`, `Focused output`, `All outputs`, `DP-1`, and `DP-2` capture modes.
- Preserve destination choices: both, file only, and clipboard only.
- Keep command arguments as argument arrays; do not construct shell command strings from UI values.

#### 4. Fix slow dismissal / self-capture

- Ensure the picker surface is removed before the capture runs: dismiss it with no/short exit animation and wait for the surface to be actually unmapped (verify the compositor has dropped it) before spawning `dms screenshot`.
- Alternatively (or in addition), add a 2–3 second pre-capture delay; if a countdown is shown, keep it off the captured target.
- Confirm latency is acceptable and that the captured image never contains the picker.

#### 5. Validate

- Build the Home Manager activation package and load the Quickshell config with no QML runtime errors or warnings caused by the picker.
- Test every target/destination combination on both monitors.
- Verify per-output region selection cannot cross onto the other output; verify any all-output region mode remains clearly labeled.
- Confirm file output, clipboard contents, notifications, cancellation, keyboard navigation, and focus restoration.
- Verify DMS theme changes update the picker as intended, or that the fallback styling remains legible.

### Risks and decisions

- DMS's current documented region mode spans outputs; its CLI does not document a per-output region flag.
- A custom region selector may need to use Wayland output geometry and account for output layout, scaling, and rotation. The DMS monitor positions are DP-1 at `(0,0)` and DP-2 at `(2560,0)`, with DP-2 rotated.
- Depending on DMS private QML internals could make the picker brittle across DMS updates; prefer documented theme data or a self-contained view styled from public settings.
- This is a Home Manager/Mango-only UI. It should not alter GNOME, Hyprland, the DMS Greeter, or DMS's own screenshot commands.
- Timing between dismissing the overlay and starting the capture is the crux of the self-capture bug: a fixed delay is simple but can still race on a slow frame, and waiting for the surface to unmap is more correct but needs a reliable signal (or a small retry). Prefer the deterministic "surface gone" approach with a short delay as fallback.

---

## 3. DMS Wallpaper Colors for WezTerm, Fish, and Neovim

### Goal

Use the palette DMS generates from the current wallpaper across WezTerm, Fish, and Neovim. When DMS changes the palette, refresh the generated app themes without replacing each app's existing configuration or losing a usable fallback.

Keep the integration user-level and declarative. Do not change the Mango, DMS Greeter, GNOME, or Hyprland setup as part of this work.

### Current setup

- DMS writes its generated palette to `~/.cache/DankMaterialShell/dms-colors.json`.
- The file contains `mode`, separate `colors.dark` and `colors.light` palettes, and a `dank16` terminal palette.
- WezTerm is configured in `config/wezterm/wezterm.lua` and currently uses the fixed built-in `Ayu Mirage` scheme. Preserve the GCR `default_ssh_auth_sock` setting while changing its theme.
- Fish's Home Manager `shellInit` runs `fish_config theme choose "ayu Mirage"`; Fish themes are also linked declaratively from `config/fish/themes`.
- Neovim's active theme setup is `config/nvim/plugin/02-colorscheme.lua`, which configures the Ayu plugin in Mirage mode.
- There is no DMS-to-terminal/editor theme synchronization yet.

### Proposed data flow

```text
DMS wallpaper palette JSON
  -> user-level theme generator
     -> generated WezTerm scheme
     -> generated Fish colors/theme
     -> generated Neovim palette/highlights
```

Keep generated artifacts under a dedicated user state/config subdirectory rather than writing into Nix-managed symlinks. The generator should read the DMS JSON, select the active light/dark palette, map semantic colors to each app, and atomically replace its output files.

Use a user-level file watcher or DMS-supported hook to run the generator when `dms-colors.json` changes, plus one initial sync when the graphical session starts. Confirm how DMS writes the file (including atomic rename behavior) before choosing `PathChanged`/`PathModified` or another watcher trigger.

### App integration

#### WezTerm

- Generate a TOML color scheme under the user's WezTerm `colors` directory using DMS's `dank16` colors for ANSI slots and the semantic palette for foreground, background, cursor, selection, and tab-bar colors.
- Set `color_scheme` to the generated scheme and ensure WezTerm watches/reloads the generated file when it changes.
- Keep `default_ssh_auth_sock` and all unrelated keybindings/config intact.

#### Fish

- Map the DMS palette to Fish syntax highlighting and pager colors.
- Do not edit the Nix-managed Ayu theme file. Prefer a generated theme file or generated Fish snippet in the dedicated sync directory.
- Decide how to update already-running Fish sessions; Fish universal-variable change handlers may be useful, while new shells should load the generated colors automatically.

#### Neovim

- Replace or override the active Ayu Mirage palette with DMS-derived highlight groups while preserving syntax/UI groups that are not part of the generated mapping.
- Keep Neovim's current Ayu setup as a fallback if the generated palette is missing or invalid.
- Decide whether running Neovim instances should reload automatically or apply the new palette on next launch, and provide a manual reload command if live updates are unreliable.

### Implementation phases

#### 1. Confirm the DMS palette contract

- Inspect representative `dms-colors.json` output after changing wallpapers in both dark and light modes.
- Identify stable fields for ANSI, foreground/background, and semantic colors; do not rely on generated values that are absent in one mode.
- Decide contrast and fallback behavior if DMS has not generated a palette yet.

#### 2. Build the generator and watcher

- Add a small user-level generator that validates JSON, maps colors, writes app-specific outputs atomically, and reports malformed or missing input without breaking shell startup.
- Add a user-level watcher/startup sync scoped so it does not run when DMS is not installed or its palette does not exist.
- Avoid polling if a file-change event can be used reliably.

#### 3. Integrate each consumer

- Wire WezTerm to the generated scheme and confirm automatic reload.
- Load generated Fish colors for both new and already-running shells without overwriting unrelated universal variables.
- Add a Neovim palette adapter that applies after the base colorscheme and survives `ColorScheme` reloads.
- Ensure all three consumers use the same DMS mode and palette revision.

#### 4. Verify wallpaper-driven updates

- Change the wallpaper in DMS and confirm the JSON changes and all three applications update.
- Test dark/light mode changes, missing/corrupt palette fallback, and application startup before the first DMS theme generation.
- Verify syntax contrast, terminal ANSI colors, selection/cursor visibility, Neovim diagnostics/LSP/UI groups, and no regression to SSH-agent behavior.

### Risks and decisions

- DMS palette output is a Material-style theme, while Ayu, Fish, and terminal ANSI schemes have different semantic expectations. Color mapping needs visual review; a direct one-to-one mapping may have poor contrast.
- A file watcher can observe a partial write unless it handles atomic replacement and debounces multiple DMS writes.
- Fish's current theme selection is declared in Home Manager; generated runtime colors must not be overwritten by that startup line.
- WezTerm reloads its config/scheme independently of Fish and Neovim. Each consumer needs a clear update mechanism and fallback.
- Decide whether existing application instances must update live or whether new instances picking up the latest palette is sufficient.

### Workstream coordination

- The project manifest loader and wallpaper-color integration both modify `config/wezterm/wezterm.lua`; implement and test them together without replacing the file wholesale.
- Preserve the GCR `default_ssh_auth_sock` setting while changing WezTerm theme loading.

---

## 4. Mango Overview & Layout Visibility

### Goal

Make the current Mango layout inspectable without a touchpad or manual `mmsg` calls: add a keyboard-reachable overview of the active tags/clients, surface the per-tag layout symbol, and resolve the Mango/WezTerm key collision that currently blocks WezTerm pane resizing.

### Current setup

- The active compositor is Mango (`mangowm`), declared in `modules/home-manager/mango.nix` under `wayland.windowManager.mango`. Runtime config resolves to `~/.config/mango/config.conf`, which sources the Nix-generated `mango-default-config.conf` plus DMS `source_optional` files.
- Layout per tag is only visible via `mmsg get all-monitors` / `mmsg get all-tags`, or incidentally in the DMS/waybar status bar. Layout symbols (`mmsg get layouts`): `T` tile, `S` scroller, `G` grid, `M` monocle, `K` deck, `CT` center_tile, `RT` right_tile, `VS` vertical_scroller, `VT` vertical_tile, `VG` vertical_grid, `VK` vertical_deck, `DW` dwindle, `F` fair, `VF` vertical_fair.
- Mango has a full overview (`toggleoverview`, `enter_overview`, `leave_overview`), but it is bound only to 4-finger touchpad swipes (`gesturebind=none,up,4,enteroverview`, `gesturebind=none,down,4,leaveoverview`). There is no keyboard binding.
- Mango's own default `SUPER+h/j/k/l` maps to `focusdir`; WezTerm's smart-splits config in `config/wezterm/wezterm.lua` sets pane resize to `META` (an alias of `SUPER`) `+ hjkl`. Mango consumes those chords globally first, so the resize bindings never reach WezTerm.

### Proposed changes

- Add a keyboard binding for the overview, e.g. `bind=SUPER,grave,toggleoverview,` in the mango module (confirm the key is free first), so the layout can be popped up on demand.
- Optionally add or confirm a layout-cycle binding that also surfaces the resulting layout symbol (`SUPER+n` is already `switch_layout`); the symbol is what the overview and status bar should agree on.
- Optionally add an active-layout-symbol indicator to the DMS shell or the `mango/workspaces` waybar module.
- Resolve the smart-splits collision: move the WezTerm pane-resize modifier off `META`/`SUPER` (e.g. `CTRL|SHIFT` or `ALT`), or explicitly align the Mango and WezTerm layers so one owner per chord is clear.

### Implementation phases

1. Confirm `toggleoverview` and the chosen key do not collide with existing binds, DMS keybinds, or keymodes; check overview behavior on both DP-1 (2560x1440) and the rotated DP-2.
2. Add the overview (and any layout-cycle) binds to `modules/home-manager/mango.nix`; rebuild home-manager.
3. If wanted, add the layout-symbol indicator to the DMS shell / waybar `mango/workspaces` module.
4. Decide and implement the smart-splits modifier change in `config/wezterm/wezterm.lua`, keeping the GCR `default_ssh_auth_sock` setting intact.
5. Validate: toggle the overview by keyboard; confirm the displayed layout matches `mmsg get all-tags`; confirm WezTerm pane resize works via the new modifier; verify no regression to Mango navigation or DMS binds.

### Status

- **Done:** `SUPER,grave,toggleoverview,` added to the bind list in `modules/home-manager/mango.nix`. `grave` was verified free in the Mango defaults, the module bind list, and DMS settings.
- **Done:** Layout-symbol indicator enabled by adding the `layout` widget id to `barConfigs[0].rightWidgets` in the runtime `~/.config/DankMaterialShell/settings.json`. DMS ships a Mango-aware `DWLLayout.qml` that reads `MangoService.getOutputState(name).layoutSymbol`; `layout_symbol` was confirmed populated live from `mmsg`. This was applied to the runtime file only (backup at `settings.json.bak-*`) because `settings.json` is still runtime-owned — see workstream 9 before making it declarative.
- **Deferred by decision:** the smart-splits `META`→`ALT` change is intentionally *not* made yet. Keybind changes across Mango/WezTerm/DMS are to be decided holistically under workstream 8 rather than piecemeal here.
- **Related:** per-output default layout by orientation is broken out into workstream 10.

### Risks and decisions

- The chosen overview key may conflict with a DMS keybind or an existing Mango bind; verify against the effective config, which merges the Nix default and the module bind list.
- Changing the smart-splits resize modifier edits `config/wezterm/wezterm.lua`, which is shared with workstreams 1 and 3; coordinate and preserve `default_ssh_auth_sock`.
- Layout indicator source of truth: whether to read it from Mango (DMS/waybar) or mirror it — avoid two divergent displays.
- This is a Home Manager/Mango/WezTerm-only change; do not alter GNOME, Hyprland, the DMS Greeter, or DMS's own tooling.

---

## 5. WezTerm Scrollback Copy Mode

### Goal

Decide how to browse and copy from WezTerm scrollback: evaluate the built-in copy mode (plus QuickSelect and Search), choose bindings that fit the Mango + Neovim + tmux-like setup, and configure them at the user level only.

### Current setup

- WezTerm `0-unstable-2026-09-29`; config `config/wezterm/wezterm.lua`; `scrollback_lines = 10000`.
- Copy mode is not customized — the stock bindings are active: `Ctrl+Shift+X` (`ActivateCopyMode`), `Ctrl+Shift+Space` (`QuickSelect`), `Ctrl+Shift+F` (`Search`), `Ctrl+Shift+C/V` (copy/paste), `Shift+PageUp/PageDown` (page scroll), `Ctrl+Shift+Up/Down`.
- The `copy_mode` key table is vi-like by default (`h/j/k/l`, `/`, `n`/`N`, `v`/`V`, `y` to yank, `Ctrl+Space` selection mode); `key_map_preference` can switch the default table style.
- Open questions: which entry key avoids Mango/DMS conflicts; selection + search + multi-line yank ergonomics; Wayland clipboard integration (`wl-clipboard`); whether copy mode should feel tmux-like or stay WezTerm-default.

### Proposed changes (exploration — decide before implementing)

- Exercise the defaults end-to-end (scroll back, search, select lines/block, yank, paste back) before deciding to change anything.
- Weigh overlap with existing binds: `Ctrl+Shift+Space` QuickSelect, the smart-splits `Ctrl+hjkl` navigation, and Mango/DMS chords.
- If changed, pick a single entry key and any `key_tables.copy_mode` overrides (or `key_map_preference`) that match muscle memory; document the chosen keys.

### Implementation phases

1. Dump the active bindings with `wezterm show-keys --lua` and list copy-mode / search / quick-select entries; note anything that collides with Mango or DMS.
2. Hands-on test each workflow inside a split, including copy/paste across panes and from a large scrollback.
3. Decide the final bindings and optional `copy_mode` table tweaks; record them.
4. If changes are made, add them to `config/wezterm/wezterm.lua` (coordinate — shared with workstreams 1, 3, and 4) and keep `default_ssh_auth_sock` intact.

### Status — complete

- Kept WezTerm's stock copy-mode, QuickSelect, and Search bindings; no custom key table or entry-key change was needed. Broader keybinding changes remain deferred to workstream 8.
- Added a visible `COPY` / `SEARCH` indicator to the fancy tab bar and right status area in `config/wezterm/wezterm.lua`, with a 500 ms update interval. The user confirmed the visual indicator is working.
- Active bindings were inspected with `wezterm show-keys --lua`, and the config was validated. Workstream is marked complete by user decision; no additional keybind changes are part of this close-out.

### Risks and decisions

- The entry key must not collide with Mango/DMS, even though the copy-mode table itself captures keys once active.
- Verify Wayland clipboard round-trips (yank to selection buffer and clipboard; paste back into the same and another pane).
- This is a user-level WezTerm-only change touching `config/wezterm/wezterm.lua`; do not alter the Mango, DMS, GNOME, or Hyprland setups.

---

## 6. Mango Window/Layer Blur

### Goal

Enable Mango's scenefx-based frosted-glass blur for windows and/or layer surfaces, tuned so it is visible without unacceptable GPU cost, and configured declaratively through the Mango Home Manager module.

### Current setup

- Blur is currently disabled: the Nix-generated default config sets `blur=0` and `blur_layer=0`. `blur_optimized=1` and the default `blur_params_*` are already present (`blur_params_radius=5`, `blur_params_num_passes=2`, `blur_params_noise=0.02`, `blur_params_brightness=0.9`, `blur_params_contrast=0.9`, `blur_params_saturation=1.2`).
- Windows are fully opaque (`focused_opacity=1.0`, `unfocused_opacity=1.0`), so even with `blur=1` tiled windows would show no visible blur.
- The effective config resolves from `~/.config/mango/config.conf`, which sources the Nix-generated default plus the DMS `source_optional` files. Overrides belong in `wayland.windowManager.mango.settings` in `modules/home-manager/mango.nix`, which is emitted after the `source = ...` line (so it wins for scalar settings).
- DMS can report compositor support for client-requested background blur via `dms blur check` (`ext-background-effect-v1`).

### Attempted change and outcome (reverted)

- Tried Mango layer blur with `blur=1`, `blur_layer=1`, and `blur_optimized=1`; increased blur parameters from the defaults to `blur_params_radius=10` and `blur_params_num_passes=3`.
- Reduced the DMS bar's runtime `transparency` from `1.0` to `0.85`, then `0.75`, to let the backdrop show through. The DMS layout widget and other bar settings were preserved.
- The user could not discern the effect at the initial setting and judged the stronger attempt not to work well / not acceptable. All blur overrides were removed and DMS bar transparency restored to `1.0`. Current state is back to blur disabled; the DMS layout widget remains enabled.
- Therefore this workstream is **not complete**. Do not simply reapply the same radius/opacity values. Before another attempt, verify that Mango's scene blur is actually being applied to the DMS layer surface, establish a clear visual test with a suitable background behind the bar, and agree on the desired appearance/performance before tuning further.

### Proposed changes

- Set `blur = 1` (windows) and/or `blur_layer = 1` (bars, docks, panels) in the mango module settings; keep `blur_optimized = 1`.
- Tune `blur_params_radius` / `blur_params_num_passes` (and noise/brightness/contrast/saturation) for strength and smoothness.
- To actually see window blur, make windows translucent: lower `focused_opacity` / `unfocused_opacity` (e.g. 0.95 / 0.9) and/or rely on apps with transparent backgrounds.
- Evaluate the extra wallpaper-blur options surfaced by the binary (`blur_layer_on_wallpaper`, `client_blur_uses_wallpaper`, `layer_blur_uses_wallpaper`, `client_sync_blur_optimized`, `layer_flush_blur_background`) for consistency with the DMS wallpaper.
- Decide whether DMS panel/menu surfaces already request blur themselves (`dms blur check`) or should rely on `blur_layer`.

### Implementation phases

1. Diagnose why the prior layer-blur attempt was not discernible/acceptable; confirm the Mango layer surface has a blur object and receives an alpha/transparency mask, and choose a clear visual test scene.
2. Confirm support and performance headroom: run `dms blur check` (this only checks client-requested blur); keep `blur_optimized=1` unless there is evidence it prevents the desired effect.
3. Agree on the appearance before changing settings again. Then enable `blur`/`blur_layer` and make only the necessary DMS layer surfaces translucent; do not change window opacity unless window blur is explicitly in scope.
4. Tune radius/passes incrementally and assess visually with the user; confirm animation smoothness and GPU impact instead of relying on configuration values alone.
5. Validate on both DP-1 (2560x1440) and rotated DP-2; confirm a clean revert to blur disabled.

### Risks and decisions

- Blur is GPU-costly; keep `blur_optimized=1` and be conservative with radius/passes (disabling optimization raises GPU use and can cause rendering lag).
- Window blur only shows through transparency, so enabling `blur` alone appears to do nothing on opaque tiled windows — opacity tuning is part of the change.
- Overrides must land after the Nix-generated `source = ...` line and must not disturb the DMS `source_optional` theming files.
- Some clients (DMS panels, menus) may already request blur through `ext-background-effect-v1`; avoid doubling the effect.
- This is a Mango/Home-Manager-only change; do not alter GNOME, Hyprland, or the DMS Greeter.

---

## 7. Firefox Chrome: Undo Rounded Design + DMS Theming

### Goal

Revert Firefox's new rounded chrome (tabs/toolbar/panels corner rounding) back to a squared look, and drive Firefox chrome colors from the DMS wallpaper palette so Firefox matches WezTerm/Fish/Neovim.

### Current setup

- Firefox is installed as a package in `home-manager/mgr8/default.nix` (line ~142). There is no `programs.firefox` block, no `userChrome.css`/`userContent.css`, and no theme generator for it.
- Firefox currently shows the new rounded design; nothing overrides the rounding.
- The DMS palette is written to `~/.cache/DankMaterialShell/dms-colors.json` and already feeds WezTerm/Fish/Neovim (workstream 3). Firefox is not yet a consumer.
- The active Firefox profile is imperative (normal `~/.mozilla/firefox/<profile>`), with real logins/bookmarks — do not replace it with a fresh managed profile.

### Proposed changes

- Enable chrome CSS: set `toolkit.legacyUserProfileCustomizations.stylesheets = true` in the profile.
- Add a `chrome/userChrome.css` that:
  - Neutralizes rounding by zeroing the relevant variables (`--tab-border-radius`, `--toolbarbutton-border-radius`, `--arrowpanel-border-radius`, toolbar/panel rounding) and the padding the new design reintroduced.
  - Maps chrome colors (`--toolbar-bgcolor`, `--lwt-accent-color`, `--tab-selected-bgcolor`, `--toolbar-color`, `--tab-selected-textcolor`, `--toolbarbutton-icon-fill`, `--arrowpanel-background`, etc.) to variables fed by the DMS palette.
- Extend the shared DMS theme generator (workstream 3) to emit a generated Firefox color snippet, and have `userChrome.css` `@import` it (keep the hand-written rules separate from generated color values).
- Optionally add `userContent.css` for `about:`/new-tab backgrounds.
- Delivery decision: use Home Manager (`programs.firefox.profiles.<name>.settings` + managed chrome files) or keep the imperative profile and manage only the chrome files via a generated path. Prefer the least-invasive option that still survives reboots.

### Implementation phases

1. Pin down exactly which rounding to remove (tabs, toolbar, popups/panels, menus) for the installed Firefox version; capture a before screenshot and list the CSS variables involved.
2. Enable legacy stylesheets and add a first `userChrome.css` that squares the chrome; verify against tabs, toolbar, and panels.
3. Extend the generator to write Firefox chrome-color variables; `@import` them from `userChrome.css`; add a fallback palette.
4. Handle reload/apply (restart Firefox, or a reload path) and missing/corrupt `dms-colors.json`.
5. Validate dark/light modes, private windows, popups/menus, and that no layout/sidebar element breaks after a wallpaper change.

### Risks and decisions

- `userChrome.css` depends on Firefox-internal CSS variables that change between versions; expect breakage on updates and keep the override minimal and documented.
- "Rounded design" may name a specific recent change; confirm the exact elements before writing broad rules so unrelated padding/geometry is not clobbered.
- Home Manager's Firefox module can create/own a profile and may conflict with the existing imperative one — avoid duplicating profiles or losing logins/bookmarks.
- Keep generated files out of the Nix store and separate from hand-written CSS; a wallpaper change should update only generated values.

---

## 8. Keybind Ergonomics (Corne Xiao)

### Goal

Iterate the Mango, WezTerm, and DMS keybindings so common actions stop requiring `Ctrl+Shift+<key>` or `Ctrl+Alt+<key>` chords whose modifiers and key land on the same hand on the split Corne Xiao keyboard.

### Current setup

- Keyboard: **Corne Xiao v2**, split 3×6 with 3 thumb keys per half, ZMK. Authoritative layout: <https://raw.githubusercontent.com/mrityunjaygr8/zmk-config-corne-xiao/refs/heads/main/keymap-drawer/corne_xiao_v2.svg> (as rendered by keymap-drawer).
- Observed layout traits: base layer carries dedicated `LCTRL`/`LSHFT` on the outer columns and `LGUI`/`LALT` on thumb keys; there are `Nav`, `Num`, and `Config` layers; the right home area holds a bracket/symbol set. There is effectively no right-hand `Ctrl`/`Shift`.
- Chords that are awkward because mods and key are same-hand:
  - Mango: `SUPER+SHIFT,{a,s,d,f,1..4,o,l,v,w}`, `SUPER+CTRL,{a,s,d,f}`, `CTRL+SHIFT,{Up,Down}`.
  - WezTerm: `CTRL|SHIFT` (tabs, sesh, backspace), `CTRL|ALT` (split), `CTRL|SHIFT|ALT` defaults (adjust pane size), `Ctrl+Shift+W/T/S`.
  - smart-splits: `CTRL` move / `META` resize (and the `META`=`SUPER` collision from workstream 4).
- Holding `LCTRL`+`LSHFT` on the left pinky cluster while pressing a left-hand letter is the specific strain to remove.

### Proposed changes

- Audit every binding by hand usage; flag any chord where two modifiers plus the key sit on one hand.
- Prefer, in order: (1) single modifier per chord, with the modifier on a **thumb** (`LGUI`/`LALT`) so the opposite hand presses the key; (2) a **leader/key-table** sequence (WezTerm leader key, Mango `keymode`, Neovim leader) for grouped actions instead of a second modifier; (3) a dedicated ZMK "hyper"/nav thumb key if a namespace is still needed.
- Rework the flagged cases:
  - WezTerm: move tab/split/resize actions to a leader key or single thumb mod; keep splits off `CTRL|ALT`.
  - Mango: replace `SUPER+SHIFT`/`SUPER+CTRL` combos with single-mod or overlay/keymode binds where mnemonic and collision-free (this subsumes the workstream-4 `META`/`SUPER` fix).
  - Consider adjusting the ZMK keymap itself (e.g., a home-row mod or a dedicated layer) if the OS side cannot be made ergonomic alone.
- Keep one documented cheatsheet (e.g. `dms keybinds`) as the source of truth for the final map.

### Implementation phases

1. Enumerate hand/mod positions from the ZMK layout (keymap-drawer source), including thumb keys and available layers.
2. Audit current binds across Mango, WezTerm, DMS, and Neovim; produce the same-hand multi-mod list.
3. Propose replacements favoring thumbs, single modifiers, and leader/keymode sequences; check for collisions with DMS and each other.
4. Implement in `modules/home-manager/mango.nix`, `config/wezterm/wezterm.lua`, and (if needed) the ZMK config; document the chosen chords.
5. Validate each action on the physical keyboard; confirm no same-hand chord remains for frequent actions and no collisions exist.

### Risks and decisions

- Every chord must remain collision-free across Mango, DMS, WezTerm, and Neovim; consolidation onto a leader reduces but does not eliminate collisions.
- Multi-modifier chords are sometimes the only free namespace; the leader/keymode approach is the more portable general fix, but changes muscle memory.
- Changes span several configs and interact with workstreams 4 and 5; coordinate so WezTerm/Mango/Neovim stay consistent.
- If the fix requires ZMK firmware changes, treat flashing as a separate, user-driven step.

---

## 9. Declarative DMS Configuration

### Goal

Manage DankMaterialShell configuration declaratively through Home Manager so every host (kharkanas, black-coral, arr, …) gets the same DMS setup without manual GUI configuration.

### Current setup

- DMS is enabled in `modules/home-manager/mango.nix`: `programs.dank-material-shell = { enable = true; systemd.enable = false; }`, using the flake input `inputs.dms.homeModules.dank-material-shell` (`dms = github:AvengeMedia/DankMaterialShell/stable`).
- No `settings` are set declaratively, so DMS writes its config **at runtime** to `~/.config/DankMaterialShell/settings.json` (currently ~3.3 KB, `configVersion 18`) with fields such as `currentThemeName: "dynamic"`, `matugenScheme`, `cornerRadius: 12`, `barConfigs` (widgets, `transparency`, `island`, per-screen `screenPreferences`), and `cursorSettings`.
- DMS also writes `~/.local/state/DankMaterialShell/session.json`, `~/.config/DankMaterialShell/clsettings.json`, `plugin_settings.json`, and generated theme outputs (`~/.cache/DankMaterialShell/dms-colors.json`, `firefox.css`, Mango `dms/colors.conf` + `layout.conf`).
- The HM module already exposes declarative options (verified in the flake input source, `distro/nix/home.nix` + `options.nix`): `settings` → `settings.json`, `clipboardSettings` → `clsettings.json`, `session` → `session.json`, `plugins.<name>.settings` → `plugin_settings.json`, `managePluginSettings`, plus `systemd.*`.

### Proposed changes

- Add a shared DMS Home Manager module (e.g. `modules/home-manager/dank-material-shell.nix`) that imports `inputs.dms.homeModules.dank-material-shell` and sets `programs.dank-material-shell.settings` to the desired bar layout / theme / cursor, so all hosts share it.
- Move the current runtime `settings.json` values into that Nix attribute set.
- Decide scope: manage `settings.json` only, or also `session.json`, `clsettings.json`, and plugin settings.
- Handle `configVersion`: DMS versions the file (now 18); decide whether to pin it or omit it and let DMS migrate, and watch for DMS rewriting the file on version bump.
- Keep theme/color **outputs** runtime-generated (`dms-colors.json`, `firefox.css`, Mango `dms/*.conf`) and out of Nix — that is workstream 3's domain.
- Decide startup ownership: currently `systemd.enable = false` and DMS is launched from Mango `autostart_sh`; consider switching to the systemd unit for consistency across hosts.

### Implementation phases

1. Diff the live `settings.json` against a minimal desired set; classify each field as shared vs host-specific (bars, `screenPreferences`, monitor names).
2. Add the shared module and move settings into Nix; rebuild home-manager.
3. Verify DMS reads the managed `settings.json` and renders the same bar/theme; observe DMS write behavior on a GUI change and on a `configVersion` migration.
4. Apply to a second host; confirm identical behavior with no manual steps.
5. Document which DMS state is declarative vs runtime-generated.

### Risks and decisions

- An HM-managed `settings.json` is a read-only symlink. If DMS writes that file at runtime (GUI widget toggles, theme change, `configVersion` bump) those writes will fail or fight HM. Confirm the write behavior first; if it writes, either accept "GUI changes don't persist" (declarative-only) or keep `settings.json` unmanaged and manage only a subset.
- `currentThemeName: "dynamic"` / `matugenScheme` are runtime/visual choices; ensure declarative settings do not fight the dynamic theming pipeline.
- Hosts differ in outputs/monitors; keep host-specific bar `screenPreferences` and Mango `monitor_rule` out of the shared module or use per-host overrides.
- The `dms` input is pinned to the `stable` branch; settings/plugin schema (`configVersion`) can change and require attribute updates.
- Keep generated files separate from declarative source (same rule as the wallpaper-color workstream).

---

## 10. Orientation-Aware Per-Output Default Layout

### Goal

Give each Mango output a sensible default layout chosen from its **geometry**, not its name: portrait (taller than wide) outputs default to a vertical layout such as `vertical_tile` (`VT`), landscape outputs default to `tile` (`T`). It must work on hosts whose output set is not fixed — notably the laptop, which is docked to different monitors — so a name-keyed rule list is not sufficient.

### Current setup

- `kharkanas` has two fixed outputs: DP-1 `2560x1440` landscape at `(0,0)`, DP-2 `1080x1920` portrait at `(2560,0)` with `rr:1`. Declared via `monitor_rule` in `modules/home-manager/mango.nix`.
- DP-2 is currently on `VT` but only for tag 1; its other tags remain `T`. This looks like a one-off manual `SUPER+n` cycle rather than a persistent default, so the setting does not survive across tags.
- `mmsg get all-monitors` reports `width` and `height` per output, which is sufficient to classify orientation (`height > width` ⇒ portrait). Live values confirm this works for both outputs.
- Mango has **no** orientation concept of its own. `monitor_rule` accepts only `name, make, model, serial, rr, scale, x, y, width, height, refresh, vrr, hdr, …`. A grep of `src/config/option_defs.c` for `portrait|orientation|transform` returns nothing.
- `tag_rule` is the declarative per-tag layout mechanism (`tag_rule=id:*,layout_name:vertical_tile`). Matching is done by `tag_rule_matches_monitor` in `src/config/reapply.c`, which supports only `monitor_name` (regex), `monitor_make`, `monitor_model`, `monitor_serial` — **not** geometry or orientation.
- `mmsg` is documented as read-only (`get`/`watch`), but `src/ipc/ipc.c` has an undocumented `dispatch <fn>,<arg>` fast path. `mmsg dispatch setlayout,monocle` was verified to work.
- `set_layout` (`src/dispatch/bind.c`) applies to `server.selected_monitor` only and takes **no** monitor argument, so per-output application requires selecting the monitor first.
- `focus_monitor` does accept an output name (`parse_monitor_arg` → `match_monitor_spec`, `arg->v` path), so `focusmon,<name>` followed by `setlayout,<layout>` is the dispatch pair to use. This pair has **not** been tested end to end yet.
- DMS ships a Mango-aware `layout` bar widget (`DWLLayout.qml`) that reads `MangoService.getOutputState(name).layoutSymbol` and can `setLayout()` itself. The widget id in `barConfigs` is `"layout"`. It is already enabled on `kharkanas`.

### Mechanism options (evaluated)

| Approach | Declarative | Orientation-aware | Survives rotation/dock | Effort |
|---|---|---|---|---|
| `tag_rule` + `monitor_name` regex | yes | no — name-keyed | no | ~4 lines |
| Startup dispatch script | no | yes — reads width/height | yes | ~20 lines + startup hook |
| DMS/QML hook | no | yes | yes, but re-applies on DMS restart | ~15 lines, brittle |

The `tag_rule` route is the cheapest and is correct for `kharkanas`' fixed pair, but it is explicitly rejected as the primary solution because the laptop's outputs vary. It remains a reasonable *fallback* for hosts that want to pin a specific monitor by name.

### Proposed design

A single orientation sync routine, run at session start and on output change, that:

1. Reads `mmsg get all-monitors`.
2. Classifies each output as portrait (`height > width`) or landscape.
3. Picks the target layout name: `vertical_tile` for portrait, `tile` for landscape. Both must be resolvable by `name` (confirmed present in `mmsg get layouts`).
4. For each output whose current layout already matches the target, skips it (avoid needless `arrange` churn and avoid clobbering a deliberate manual override mid-session).
5. For each mismatched output, dispatches `focusmon,<name>` then `setlayout,<layout>`.
6. Restores the originally selected monitor afterwards so focus does not visibly jump.

Open questions to settle before implementing:

- **Scope of tags.** `setlayout` affects only the current tag of the selected monitor. Defaults for *all* tags need either a `tag_rule` with `id:*` as a base, or a loop over tags. Prefer a `tag_rule` base for per-tag defaults plus the dispatch routine for orientation correction of the active tag.
- **When to run.** Options: `autostart_sh` only; additionally on output hotplug. Mango exposes `watch all-monitors`, which can drive a long-lived watcher.
- **Manual override respect.** If the user cycles layout with `SUPER+n`, the sync must not immediately undo it. Either run only on output changes (not periodically) or record an override timestamp.
- **Per-host opt-in.** `kharkanas` is fixed and could use the simple `tag_rule`; the laptop needs the geometry-driven path. Decide whether both hosts run the same routine (uniform, slightly more work) or the module takes an option such as `mango.orientationLayouts.enable`.

### Implementation phases

1. Verify the `focusmon,<name>` + `setlayout,<name>` dispatch pair on both outputs; confirm focus is restored and that `arrange` settles before the next dispatch.
2. Write the sync script as a `writeShellScriptBin` in `modules/home-manager/mango.nix`, using `mmsg` plus `jq` (both already used in that module).
3. Add a `tag_rule` base so every tag gets a sane default, independent of the active-tag correction.
4. Wire the script into `autostart_sh`; decide whether to add a `watch all-monitors` loop for hotplug.
5. Validate on `kharkanas` (rotate DP-2's `rr` value to simulate orientation change) and on the laptop with at least one docked and one undocked output set.
6. Confirm no regression to `SUPER+n` manual cycling, and that the DMS `layout` widget symbol agrees with the applied layout.

### Risks and decisions

- `mmsg dispatch` is undocumented; it could change across Mango versions. Keep the logic isolated in one script so it is easy to replace, and fail soft if a dispatch returns `unknown function`.
- `setlayout` clobbers the current tag's layout and calls `clear_fullscreen_and_maximized_state`, so running it while a client is fullscreen would be disruptive. Skip outputs that currently have a fullscreen/maximized client, or only run at startup and on hotplug.
- The dispatch pair changes the selected monitor twice per output; on a multi-output host this can produce a visible focus flicker. Prefer restoring focus in a single pass at the end.
- Orientation is inferred from `width`/`height`, which reflects the *current* transform. That is the desired behavior for rotation, but it means the routine must re-run after a rotation rather than being computed once at config time.
- Hosts differ in outputs; keep this out of any shared host-agnostic module or gate it behind a per-host option.
- Do not disturb `monitor_rule` (position/scale/rotation) — this workstream only sets layouts.

---

## Resume checklist

1. Choose a workstream and inspect its current config before editing.
2. Resolve the open design decisions in that workstream.
3. Implement only that workstream while preserving shared constraints.
4. Run its listed validation and test steps before marking it complete.
