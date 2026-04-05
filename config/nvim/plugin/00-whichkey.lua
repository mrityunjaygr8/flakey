vim.pack.add({"https://github.com/folke/which-key.nvim"})

require("which-key").setup({spec = {      { "<C-d>", "<C-d>zz", desc = "Half page down and center" },
      { "<C-u>", "<C-u>zz", desc = "Half page up and center" },
      { "J", "mzJ`z", desc = "Join lines and keep cursor position" },
      { "N", "Nzzzv", desc = "Previous search result and center" },
      { "n", "nzzzv", desc = "Next search result and center" },
              { "<leader>c", group = "[C]ode Actions" },
        { "<leader>e", group = "[E]xplorer" },
        { "<leader>f", group = "[F]ormat File" },
        { "<leader>h", group = "[H]arpoon" },
        { "<leader>n", group = "Clear/[N]o Search Highlights" },
        { "<leader>r", group = "[R]ename" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>x", group = "Trouble" },
        { "<leader>q", group = "[Q]uit" },
        { "<leader>l", group = "[L]azygit" },
        { "<leader>t", group = "[T]odo Comments" },
    }})
