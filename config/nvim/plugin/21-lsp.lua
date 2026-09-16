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

-- --- effect-tsgo (Effect LSP for TypeScript-Go), opt-in per project ---
-- Find the nearest ancestor project that has @effect/tsgo installed locally.
local function effect_tsgo_project_root(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local dir = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
	while dir do
		if vim.uv.fs_stat(dir .. "/node_modules/@effect/tsgo/package.json") then
			return dir
		end
		local parent = vim.fs.dirname(dir)
		if parent == dir or parent == nil then
			return nil
		end
		dir = parent
	end
end

-- Resolve the native effect-tsgo binary for a project (cached per root).
local effect_tsgo_exe_cache = {}
local function effect_tsgo_exe(root)
	local cached = effect_tsgo_exe_cache[root]
	if cached ~= nil then
		return cached
	end
	local bin = vim.fs.joinpath(root, "node_modules", ".bin", "effect-tsgo")
	if vim.fn.executable(bin) ~= 1 then
		effect_tsgo_exe_cache[root] = false
		return false
	end
	local res = vim.system({ bin, "get-exe-path" }, { cwd = root, text = true }):wait()
	local exe = false
	if res.code == 0 then
		for line in (res.stdout or ""):gmatch("[^\r\n]+") do
			line = vim.trim(line)
			if line ~= "" then
				exe = line
			end
		end
	else
		vim.notify("effect-tsgo get-exe-path failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
	end
	effect_tsgo_exe_cache[root] = exe
	return exe
end

local ts_ls_default = vim.lsp.config["ts_ls"]

vim.lsp.config("tsgo", {
	capabilities = blink.get_lsp_capabilities(),
	cmd = function(dispatchers, config)
		local exe = config.root_dir and effect_tsgo_exe(config.root_dir)
		if not exe then
			vim.notify("effect-tsgo: could not resolve executable", vim.log.levels.ERROR)
			return
		end
		return vim.lsp.rpc.start({ exe, "--lsp", "--stdio" }, dispatchers)
	end,
	root_dir = function(bufnr, on_dir)
		local root = effect_tsgo_project_root(bufnr)
		if root then
			on_dir(root)
		end
	end,
})
vim.lsp.enable("tsgo")

-- Keep ts_ls as the default, but skip it inside effect-tsgo projects.
-- If effect-tsgo is present but cannot resolve its binary, fall back to ts_ls
-- so the project still gets a working TypeScript LSP.
servers.ts_ls = {
	root_dir = function(bufnr, on_dir)
		local root = effect_tsgo_project_root(bufnr)
		if root and effect_tsgo_exe(root) then
			return
		end
		ts_ls_default.root_dir(bufnr, on_dir)
	end,
}

for server, config in pairs(servers) do
	config.capabilities = blink.get_lsp_capabilities()
	vim.lsp.config(server, config)
	vim.lsp.enable(server)
end
