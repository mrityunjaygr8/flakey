return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    {"<leader>lg", function() Snacks.lazygit() end, desc = "Open lazygit"},
    {"<leader>ee", function() Snacks.explorer() end, desc = "Toggle the explorer"},
    {"<leader>ef", function() Snacks.explorer() end, desc = "Current File"},

  },
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = {enabled = true, replace_netrw = true},
    indent = { enabled = true },
    input = { enabled = true },
    lazygit = {enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
}
