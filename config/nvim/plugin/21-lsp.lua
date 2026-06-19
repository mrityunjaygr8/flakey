vim.pack.add({
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/saghen/blink.cmp",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/b0o/SchemaStore.nvim",
})

require("lazydev").setup({})
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
		end
		local Snacks = require("snacks")

		map("gR", Snacks.picker.lsp_references, "Show LSP references") -- show definition, references
		map("gD", vim.lsp.buf.declaration, "Go to declaration") -- go to declaration
		map("gd", Snacks.picker.lsp_definitions, "Show LSP definitions") -- show lsp definitions
		map("gi", Snacks.picker.lsp_implementations, "Show LSP implementations") -- show lsp implementations
		map("gt", Snacks.picker.lsp_type_definitions, "Type Definition") -- show lsp type definitions
		map("<leader>ca", vim.lsp.buf.code_action, "See available code actions") -- see available code actions, in visual mode will apply to selection
		map("<leader>rn", vim.lsp.buf.rename, "Smart rename") -- smart rename
		map("<leader>Ss", Snacks.picker.lsp_symbols, "LSP Symbols")
		map("<leader>SS", Snacks.picker.lsp_workspace_symbols, "LSP Workspace Symbols")
		map("K", vim.lsp.buf.hover, "Show documentation for what is under cursor") -- show documentation for what is under cursor
		map("<leader>rs", ":LspRestart<CR>", "Restart LSP") -- mapping to restart lsp if necessary
	end,
})
local blink = require("blink.cmp")

blink.setup({
	keymap = { preset = "super-tab" },
	fuzzy = { implementation = "lua" },
	completion = {
		documentation = { auto_show = true, auto_show_delay_ms = 500 },
	},
	signature = { enabled = true },
	sources = {
		-- add lazydev to your completion providers
		default = { "lazydev", "lsp", "path", "snippets", "buffer" },
		per_filetype = {
			sql = { "snippets", "dadbod", "buffer" },
		},
		providers = {
			dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
			lazydev = {
				name = "LazyDev",
				module = "lazydev.integrations.blink",
				-- make lazydev completions top priority (see `:h blink.cmp`)
				score_offset = 100,
			},
		},
	},
})
local servers = {
	lua_ls = {},
	rust_analyzer = {},
	gopls = {},
	ts_ls = {},
	nixd = {},
	bashls = {},
	helm_ls = {},
	tofu_ls = {},
	-- terraformls = {
	-- 	cmd = { "terraform-ls", "serve", "-path", "tofu" },
	-- },
	-- ty = {},
	pyrefly = {},
	tinymist = {},
	elixirls = {
		cmd = { "elixir-ls" },
	},
	jsonls = {
		schemas = require("schemastore").json.schemas(),
		validate = { enable = true },
	},
	yamlls = {
		schemastore = {
			enable = false,
			url = "",
		},
		schemas = require("schemastore").yaml.schemas(),
	},
}

for server, config in pairs(servers) do
	config.capabilities = blink.get_lsp_capabilities()
	vim.lsp.config(server, config)
	vim.lsp.enable(server)
end
