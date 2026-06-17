---
name: plans-in-typst-not-markdown
description: "Write planning documents as .typ files, compile to PDF, and copy both source and PDF to cwd — never .md for plans"
condition: "[Pp]lan"
scope: ["tool:write(local://*-plan.md)", "tool:edit(local://*-plan.md)"]
---

Plans MUST be written in Typst format (`.typ`), not Markdown (`.md`). Match the preamble of existing reference documents (e.g. `production-deployment-plan.typ`): use `#set page(margin: (x: 2.5cm, y: 2cm), numbering: "1")`, `#set heading(numbering: "1.")`, centered title block with `#align(center, text(...))`, and `#outline(title: "Table of Contents", indent: auto)`. After writing the `.typ` file, compile with `typst compile` and copy **both** the `.typ` source and the compiled `.pdf` to the current working directory for git.