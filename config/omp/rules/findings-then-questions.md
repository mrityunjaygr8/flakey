---
name: findings-then-questions
description: "Present findings first, wait for user review before asking questions — never combine in one turn"
condition: ["(?:the(?:se)?\\s+(?:above|issues?|findings?|items?)|which\\s+(?:of\\s+)?(?:the|these)|I(?:'ve)?\\s+(?:found|listed|identified|spotted)|how\\s+(?:should|to|would)\\s+(?:I|we)\\s+(?:fix|handle|address|proceed|resolve))", "(?:what|how)\\s+(?:should|to|do|would)\\s+(?:I|we|you)\\s+(?:do|fix|handle|address|change|update|proceed)"]
scope: "tool:ask"
---

Present findings first and STOP. Never use the ask tool in the same response as presenting findings, issues, or analysis.

Required workflow:

1. **Present findings** — state what you found, then end with: "Let me know when you're ready for me to ask clarifying questions."
2. **Wait** — the user reviews the findings and may give early direction.
3. **User says 'ask questions' or 'ok, questions'** — only THEN use the ask tool.
4. **User answers** — review their answers. If the plan still needs refinement, go back to step 1.
5. **Loop** steps 1-4 until the user is satisfied with the plan.
6. **User explicitly approves** ("go ahead", "proceed", "yup", "approved", "make changes") — only THEN make file edits or run destructive commands.

Information-gathering commands (reads, searches, non-destructive bash) are always allowed without approval. Only file creation/edits and destructive commands must wait for explicit go-ahead.