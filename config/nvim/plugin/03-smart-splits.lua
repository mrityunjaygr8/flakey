vim.pack.add({ "https://github.com/smart-splits-nvim/smart-splits.nvim" })
vim.pack.add({ "https://github.com/smart-splits-nvim/backend-kitty" })
vim.pack.add({ "https://github.com/smart-splits-nvim/backend-wezterm" })

local ssw = require("smart-splits-backend-wezterm")
local ss = require("smart-splits")

ssw.setup({})

ss.setup({
	mux = {
		backend = "smart-splits-backend-wezterm",
	},
})

local map = vim.keymap.set

-- move between nvim windows / kitty splits
map("n", "<c-h>", ss.move_cursor_left, { desc = "Move to split left" })
map("n", "<c-j>", ss.move_cursor_down, { desc = "Move to split down" })
map("n", "<c-k>", ss.move_cursor_up, { desc = "Move to split up" })
map("n", "<c-l>", ss.move_cursor_right, { desc = "Move to split right" })
