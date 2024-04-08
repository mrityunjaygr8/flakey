return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-fzf-native.nvim",
		"nvim-tree/nvim-web-devicons",
		"folke/todo-comments.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
			},
		})

		-- telescope.load_extension("fzf")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>sf", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy [S]earch files in cwd" })
		keymap.set("n", "<leader>sr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy [S]earch recent files" })
		keymap.set("n", "<leader>ss", "<cmd>Telescope live_grep<cr>", { desc = "[S]earch string in cwd" })
		keymap.set(
			"n",
			"<leader>sc",
			"<cmd>Telescope grep_string<cr>",
			{ desc = "[S]earch string under cursor in cwd" }
		)
		keymap.set("n", "<leader>st", "<cmd>TodoTelescope<cr>", { desc = "[S]earch Todos" })
		keymap.set("n", "<leader> ", "<cmd>Telescope buffers<cr>", { desc = "Show open buffers" })
	end,
}
