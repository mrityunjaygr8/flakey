vim.pack.add({ "https://github.com/shatur/neovim-ayu" })
require("ayu").setup({
	mirage = true,
})
vim.cmd("colorscheme ayu")
