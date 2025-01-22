-- return {
-- 	"catppuccin/nvim",
-- 	name = "catppuccin",
-- 	priority = 1000,
-- 	config = function()
-- 		require("catppuccin").setup({
-- 			default_integrations = true,
-- 		})
-- 		vim.cmd([[colorscheme catppuccin-mocha]])
-- 	end,
-- }

return {
	"nuvic/flexoki-nvim",
	name = "flexoki",
	priority = 1000,
	config = function()
		require("flexoki").setup({
			variant = "moon",
			enable = {
				terminal = true,
			},
		})

		vim.cmd([[colorscheme flexoki]])
	end,
}
