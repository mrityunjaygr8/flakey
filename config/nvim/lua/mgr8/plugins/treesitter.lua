return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function() 
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      ensure_installed = {
        "lua",
        "vim",
        "elixir",
        "heex",
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
        "nginx",
        "nix",
        "toml",
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
        },
      },
    })
  end
}
