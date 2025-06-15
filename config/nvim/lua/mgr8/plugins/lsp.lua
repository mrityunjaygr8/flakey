return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  { -- optional blink completion source for require statements and module annotations
    "saghen/blink.cmp",
    version = '1.*',
    opts = {
      keymap = { preset = "default"},
      fuzzy = {implementation = "lua"},
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'saghen/blink.cmp' },

    -- example using `opts` for defining servers
    opts = {
      servers = {
        lua_ls = {},
        pyright = {},
        gopls = {},
        ts_ls = {},
        nixd = {},
        bashls = {},
        terraformls = {}
      }
    },
    config = function(_, opts)
      local lspconfig = require('lspconfig')
      local keymap = vim.keymap
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local map = function (keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = ev.buf, desc = "LSP: " .. desc})
          end
          local Snacks = require("snacks")

          map("gR", Snacks.picker.lsp_references, "Show LSP references") -- show definition, references
          map("gD", vim.lsp.buf.declaration,  "Go to declaration") -- go to declaration
          map("gd", Snacks.picker.lsp_definitions, "Show LSP definitions" ) -- show lsp definitions
          map("gi", Snacks.picker.lsp_implementations,  "Show LSP implementations") -- show lsp implementations
          map("gt", Snacks.picker.lsp_type_definitions, "Type Definition") -- show lsp type definitions
          map("<leader>ca", vim.lsp.buf.code_action,  "See available code actions") -- see available code actions, in visual mode will apply to selection
          map("<leader>rn", vim.lsp.buf.rename,  "Smart rename") -- smart rename
          map("<leader>Ss", Snacks.picker.lsp_symbols, "LSP Symbols")
          map("<leader>SS", Snacks.picker.lsp_workspace_symbols, "LSP Workspace Symbols")
          map("K", vim.lsp.buf.hover,  "Show documentation for what is under cursor") -- show documentation for what is under cursor
          map("<leader>rs", ":LspRestart<CR>",  "Restart LSP") -- mapping to restart lsp if necessary
        end,
      })
      for server, config in pairs(opts.servers) do
        -- passing config.capabilities to blink.cmp merges with the capabilities in your
        -- `opts[server].capabilities, if you've defined it
        config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end
    end
  }
}
