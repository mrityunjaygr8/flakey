---
name: browser-tool-not-for-navigation
description: "Use chrome-devtools MCP to open/navigate/browse URLs, not the built-in browser tool"
condition: "\"action\"\\s*:\\s*\"open\""
scope: "tool:browser"
---

When the user says open, go to, navigate to, browse, or show a URL, use the Chrome DevTools MCP browser: `mcp__chrome_devtools_new_page` for a new tab, or `mcp__chrome_devtools_navigate_page` for an existing one. The built-in `browser` tool is only for headless programmatic use: research, automation, scraping, or reading page content. Never use `browser` with `action: "open"` for user-facing browsing.