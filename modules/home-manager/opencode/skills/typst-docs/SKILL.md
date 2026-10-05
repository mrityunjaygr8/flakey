---
name: Typst Documents
description: Write or edit Typst (.typ) documents in the VLCM house style — the ilm template, Geist fonts, section/callout/table conventions, decision-table structure, and the font-path build command. Use whenever a .typ file is created or modified.
---

# Typst Documents

Apply these conventions to every Typst document in the VLCM repos so the format
does not have to be restated each time.

## Build

Fonts come from home-manager and are **not** on typst's default search path —
pass them explicitly, or the render silently falls back and warns:

```bash
typst compile \
  --font-path ~/.nix-profile/share/fonts \
  --font-path ~/.local/share/fonts \
  doc.typ doc.pdf
```

`scripts/build.sh` wraps this. Compile after every edit and confirm exit 0 with
no font warnings.

## Header (copy verbatim, then edit title and date)

```typ
#import "@preview/ilm:2.0.0": blockquote, ilm
#set page(numbering: "1")
#set text(font: ("Geist", "Liberation Serif"), size: 11pt)
#show raw: set text(font: "Geist Mono", size: 9pt)

#let project = "VLCM"
#let doc-title = "Short Title"

#show: ilm.with(
  title: [Full Document Title],
  authors: ("Engineering Notes",),
  date: datetime(year: 2026, month: 10, day: 05),
  table-of-contents: outline(depth: 2),
  raw-text: (font: "Geist Mono", size: 9pt),
)
```

- `raw-text` is required. Without it, `ilm`'s internal Iosevka/Fira default wins
  and code blocks do not render in Geist Mono.
- Use `@preview/ilm:2.0.0` with `blockquote, ilm` for plans and notes. For
  whitepapers use `@preview/ilm:2.1.1` with `*` and the `abstract`,
  `figure-index`, `table-index`, `listing-index` options.

## Structure

- `==` for sections, `===` for subsections. Never `=`.
- Open with `== Context`; state hard constraints in a `#blockquote[...]`.
- Put settled choices in a decision table, for example "Agreed Decisions" or
  "Design Decisions".
- For plans, one `===` per phase, each ending with a "Gate" table of checks.
- End with `== Open questions` when decisions remain.
- Tone: concise engineering notes, not marketing.

## Callouts

```typ
#blockquote[
  *Bold lead-in:*
  - point one
  - point two
]
```

## Tables

Bold-header table with `inset: 6pt` and `stroke: 0.5pt`:

```typ
#table(
  columns: (1fr, 1.6fr, 1.6fr),
  inset: 6pt,
  stroke: 0.5pt,
  table.header([*Option*], [*Pros*], [*Cons*]),
  [Row label], [prose], [prose],
)
```

Do **not** use `auto` for a column holding prose or code. `auto` sizes to the
widest unbreakable run, so one long identifier or sentence makes that column eat
the page and the `1fr` columns collide. Use proportional widths throughout:
`(1fr, 1.6fr, 1.6fr)` for pros/cons tables, `(1.2fr, 2fr, 1.2fr)` when the
middle column is the long one. `auto` is only safe when every cell is short,
such as a cost table of numbers.

Some existing docs use the lighter style instead:
`stroke: (y: 0.5pt + luma(200))` with `[*Col*]` cells and no `table.header`.

## Diagrams and trees

Fenced block with the `text` language:

````
```text
hosting/
└── tofu/
    ├── base/
    └── instance/
```
````

Code blocks wrap at roughly 78 characters, and a wrapped tree looks broken.
Keep lines shorter than that, or restructure the diagram so nothing runs wide.

## Typst gotchas (these fail silently)

- Wrap every identifier containing `_` in backticks. Bare `least_outstanding_requests`
  in prose becomes italic text.
- `$` starts math mode. Write money in backticks (`` `$17` ``) or escape it as `\$17`.
- `~` is a non-breaking space, not "approximately". Write "about" or "approx.".
- `#` starts code and `@` starts a reference. Escape as `\#` and `\@` in prose.
- Inline code does **not** wrap: a long identifier overflows a narrow cell. Add
  the break rule below whenever cells or narrow columns carry long identifiers.
- Keep the header block's order; `raw-text` must sit inside `ilm.with(...)`.

Break rule for long inline code (renders it as mono text with a zero-width
break opportunity after each underscore, used only when the line needs it):

```typ
#show raw.where(block: false): it => text(
  font: "Geist Mono", size: 9pt,
  it.text.replace("_", "_\u{200B}"),
)
```

## Output

Compile the PDF to a scratch location (for example `/tmp/opencode/`) to verify;
the `.typ` source is the artifact. Do not commit the PDF unless asked.
