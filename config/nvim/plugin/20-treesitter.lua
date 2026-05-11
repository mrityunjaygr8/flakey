vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "nvim-treesitter" and kind == "update" then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "<filetype>" },
	callback = function()
		vim.treesitter.start()
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" } })

require("nvim-treesitter").install({
	"lua",
	"vim",
	"python",
	"go",
	"typescript",
	"tsx",
	"yaml",
	"html",
	"css",
	"markdown",
	"markdown_inline",
	"bash",
	"dockerfile",
	"gitignore",
	"rust",
	"sql",
	"csv",
	"fish",
	"json",
	"json5",
	"nix",
	"toml",
	"typst",
})

-- local tsc = require("nvim-treesitter.config")
-- tsc.setup({
-- 			sync_install = true,
-- 			auto_install = true,
-- 			ignore_install = {},
-- 			modules = {},
-- 			highlight = {
-- 				enable = true,
-- 			},
-- 			indent = {
-- 				enable = true,
-- 			},
-- 			autotag = {
-- 				enable = true,
-- 			},
-- 			ensure_installed = {
-- 				"lua",
-- 				"vim",
-- 				"python",
-- 				"go",
-- 				"typescript",
-- 				"tsx",
-- 				"yaml",
-- 				"html",
-- 				"css",
-- 				"markdown",
-- 				"markdown_inline",
-- 				"bash",
-- 				"dockerfile",
-- 				"gitignore",
-- 				"rust",
-- 				"sql",
-- 				"csv",
-- 				"fish",
-- 				"json",
-- 				"json5",
-- 				"jsonc",
-- 				"nix",
-- 				"toml",
--       }
-- })
