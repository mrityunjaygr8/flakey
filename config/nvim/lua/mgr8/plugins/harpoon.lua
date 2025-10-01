return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		vim.keymap.set("n", "<leader>hh", function()
			harpoon:list():add()
		end, { desc = "Add file to [[h]]arpoon" })

		vim.keymap.set("n", "<leader>hl", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Open [h]arpoon [l]ist" })

		vim.keymap.set("n", "<leader>ha", function()
			harpoon:list():select(1)
		end, { desc = "Move to file 1" })
		vim.keymap.set("n", "<leader>hs", function()
			harpoon:list():select(2)
		end, { desc = "Move to file 2" })
		vim.keymap.set("n", "<leader>hd", function()
			harpoon:list():select(3)
		end, { desc = "Move to file 3" })
		vim.keymap.set("n", "<leader>hf", function()
			harpoon:list():select(4)
		end, { desc = "Move to file 4" })
		vim.keymap.set("n", "<leader>hg", function()
			harpoon:list():select(5)
		end, { desc = "Move to file 5" })

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<leader>hp", function()
			harpoon:list():prev()
		end, { desc = "Move to previous harpoon buffer" })
		vim.keymap.set("n", "<leader>hn", function()
			harpoon:list():next()
		end, { desc = "Move to next harpoon buffer" })
	end,
}
