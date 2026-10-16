vim.pack.add({ "https://github.com/smart-splits-nvim/smart-splits.nvim" })
vim.pack.add({ "https://github.com/smart-splits-nvim/backend-kitty" })

local ss = require("smart-splits")
ss.setup({
	mux = {
		backend = "smart-splits-backend-kitty-lua",
	},
})
