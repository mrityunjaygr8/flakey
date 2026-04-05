vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'nvim-treesitter' and kind == 'update' then
    if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
    vim.cmd('TSUpdate')
  end
end })

vim.pack.add({ 'https://github.com/nvim-treesitter/nvim-treesitter' , version = "main" })

local ts = require("nvim-treesitter.configs")
ts.setup({
			sync_install = true,
			auto_install = true,
			ignore_install = {},
			modules = {},
			highlight = {
				enable = true,
			},
			indent = {
				enable = true,
			},
			autotag = {
				enable = true,
			},
			ensure_installed = {
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
				"jsonc",
				"nix",
				"toml",
})
