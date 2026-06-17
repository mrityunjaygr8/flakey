---
name: plans-in-typst-not-markdown
description: "Write planning documents as .typ and .md files, compile to PDF, and copy source .typ and PDF to cwd"
condition: "[Pp]lan"
scope: ["tool:write(local://*-plan.md)", "tool:edit(local://*-plan.md)"]
---

Plans MUST be written in Typst format (`.typ`) and Markdown (`.md`). The Markdown for the harness to use the resolve tool, and typst for user reference. The content should be the same in both cases, only the formatting should change. When editing the plan, update/edit the typst document as well as the markdown doc. Match the preamble of existing reference documents (e.g. `production-deployment-plan.typ`): use `#set page(margin: (x: 2.5cm, y: 2cm), numbering: "1")`, `#set heading(numbering: "1.")`, centered title block with `#align(center, text(...))`, and `#outline(title: "Table of Contents", indent: auto)`. After writing the `.typ` file, compile with `typst compile` and copy **both** the `.typ` source and the compiled `.pdf` to the current working directory for git.

