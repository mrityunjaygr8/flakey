vim.pack.add({"https://github.com/alexghergh/nvim-tmux-navigation"})

require("nvim-tmux-navigation").setup({
  keybinds = {
					left = "<C-h>",
					down = "<C-j>",
					up = "<C-k>",
					right = "<C-l>",
					last_active = "<C-\\>",
					next = "<C-Space>",

  }
})


