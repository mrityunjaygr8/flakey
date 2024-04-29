return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 500
	end,
	config = function()
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		require("which-key").register({
			["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
			["<leader>c"] = { name = "[C]ode Actions", _ = "which_key_ignore" },
			["<leader>e"] = { name = "[E]xplorer", _ = "which_key_ignore" },
			["<leader>f"] = { name = "[F]ormat File", _ = "which_key_ignore" },
			["<leader>n"] = { name = "Clear Search Highlights", _ = "which_key_ignore" },
			["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
			["<leader>h"] = { name = "[H]arpoon", _ = "which_key_ignore" },
			["<leader>x"] = { name = "Trouble", _ = "which_key_ignore" },
		})
	end,
}
