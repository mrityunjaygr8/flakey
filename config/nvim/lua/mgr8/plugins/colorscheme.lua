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
