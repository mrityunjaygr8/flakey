return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			default_integrations = true,
		})
		vim.cmd([[colorscheme catppuccin-mocha]])
	end,
}
