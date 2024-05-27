return {
	"diegoulloao/neofusion.nvim",
	priority = 1000,
	config = function()
		require("neofusion").setup({
			transparent_mode = true,
		})
	end,
	opts = function()
		vim.o.background = "dark"
		vim.cmd([[ colorscheme neofusion ]])
	end,
}
