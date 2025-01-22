return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 1000
  end,
  config = function()
    require("which-key").add({
      { "<C-d>", "<C-d>zz", desc = "Half page down and center" },
      { "<C-u>", "<C-u>zz", desc = "Half page up and center" },
      { "<leader>c", group = "[C]ode Actions" },
      { "<leader>e", group = "[E]xplorer" },
      { "<leader>f", group = "[F]ormat File" },
      { "<leader>h", group = "[H]arpoon" },
      { "<leader>n", group = "Clear Search Highlights" },
      { "<leader>r", group = "[R]ename" },
      { "<leader>s", group = "[S]earch" },
      { "<leader>x", group = "Trouble" },
      { "J", "mzJ`z", desc = "Join lines and keep cursor position" },
      { "N", "Nzzzv", desc = "Previous search result and center" },
      { "n", "nzzzv", desc = "Next search result and center" },
    })
  end,

}
