return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  config = function()
    require("which-key").register({
      J = {"mzJ`z", "Join lines and keep cursor position"},
      ["<C-d>"] = {"<C-d>zz", "Half page down and center"},
      ["<C-u>"] = {"<C-u>zz", "Half page up and center"},
      n = { "nzzzv", "Next search result and center" },
      N = { "Nzzzv", "Previous search result and center" },
      ["<leader>"] = {
        s = { name = "[S]earch", _ = "which_key_ignore" },
        c = { name = "[C]ode Actions", _ = "which_key_ignore" },
        e = { name = "[E]xplorer", _ = "which_key_ignore" },
        f = { name = "[F]ormat File", _ = "which_key_ignore" },
        n = { name = "Clear Search Highlights", _ = "which_key_ignore" },
        r = { name = "[R]ename", _ = "which_key_ignore" },
        h = { name = "[H]arpoon", _ = "which_key_ignore" },
        x = { name = "Trouble", _ = "which_key_ignore" },
      }
      
    })
  end,

}
