vim.pack.add({
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
	"https://github.com/nvim-lua/plenary.nvim",
})

local h = require("harpoon")
local wk = require("which-key")
h:setup()
wk.add({
	{
		"<leader>hh",
		function()
			h:list():add()
		end,
		desc = "Add to Harpoon",
	},
	{
		"<leader>hl",
		function()
			h.ui:toggle_quick_menu(h:list())
		end,
		desc = "List Harpooned Files",
	},
	{
		"<leader>ha",
		function()
			h:list():select(1)
		end,
		desc = "Move to File 1",
	},
	{
		"<leader>hs",
		function()
			h:list():select(2)
		end,
		desc = "Move to File 2",
	},
	{
		"<leader>hd",
		function()
			h:list():select(3)
		end,
		desc = "Move to File 3",
	},
	{
		"<leader>hf",
		function()
			h:list():select(4)
		end,
		desc = "Move to File 4",
	},
	{
		"<leader>hg",
		function()
			h:list():select(5)
		end,
		desc = "Move to File 5",
	},
	{
		"<leader>hp",
		function()
			h:list():prev()
		end,
		desc = "Move to Previous File",
	},
	{
		"<leader>hn",
		function()
			h:list():next()
		end,
		desc = "Move to Next File",
	},
})
