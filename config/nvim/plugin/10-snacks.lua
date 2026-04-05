vim.pack.add({"https://github.com/folke/snacks.nvim"})

local s = require("snacks")
s.setup({
		bigfile = { enabled = true },
		explorer = { enabled = true, replace_netrw = true },
		indent = { enabled = true, animate = { enabled = false } },
		input = { enabled = true },
		lazygit = { enabled = true },
		picker = { enabled = true },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
})

local wk = require("which-key")

wk.add({
  {"<leader>ee", function() s.explorer() end, desc = "Toggle Explorer"},
  {"<leader>lg", function() s.lazygit() end, desc = "Open [L]azy[G]it", group = "[L]azy[G]it"},
  {"<leader>sb", function() s.pickers.buffers() end, desc = "Buffers", group = "[S]earch"},
  {"<leader>sf", function() s.pickers.files() end, desc = "Find Files", group = "[S]earch"},
  {"<leader>ss", function() s.pickers.grep() end, desc = "Grep", group = "[S]earch"},
  {"<leader><leader>", function() s.pickers.smart() end, desc = "Smart Find Files", group = "[S]earch"},
})
