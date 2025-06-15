return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    {"<leader>lg", function() Snacks.lazygit() end, desc = "Open lazygit"},
    {"<leader>ee", function() Snacks.explorer() end, desc = "Toggle the explorer"},
    {"<leader>ef", function() Snacks.explorer() end, desc = "Current File"},
    -- find
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
    { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
  },
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = {enabled = true, replace_netrw = true},
    indent = { enabled = true, animate = { enabled = false }},
    input = { enabled = true },
    lazygit = {enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
}
