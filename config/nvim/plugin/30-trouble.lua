vim.pack.add({ "https://github.com/folke/trouble.nvim" })

require("trouble").setup()

local wk = require("which-key")
wk.add({
	{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics", group = "Trouble" },
	{
		"<leader>xX",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		desc = "Diagnostics (Buffer)",
		group = "Trouble",
	},
})
