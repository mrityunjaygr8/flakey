vim.pack.add({ "https://github.com/hat0uma/csvview.nvim" })
local wk = require("which-key")
local csvview = require("csvview")
csvview.setup({})

wk.add({
	{
		"<leader>v",
		function()
			csvview.toggle()
		end,
		desc = "Toggle Csv[V]iew",
		group = "Csv[V]iew",
	},
})
