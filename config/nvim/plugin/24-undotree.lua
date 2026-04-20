vim.cmd("packadd nvim.undotree")

local u = require("undotree")
local wk = require("which-key")
wk.add({
	{
		"<leader>u",
		function()
			u.open()
		end,
		desc = "Open UndoTree",
		group = "[U]ndoTree",
	},
})
