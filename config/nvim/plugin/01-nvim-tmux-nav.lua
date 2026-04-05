vim.pack.add({"https://github.com/alexghergh/nvim-tmux-navigation"})

local ntn = require("nvim-tmux-navigation")
ntn.setup({})

local wk = require("which-key")
wk.add({
  {"<c-h>", function() ntn.NvimTmuxNavigateLeft() end},
  {"<c-l>", function() ntn.NvimTmuxNavigateRight() end},
  {"<c-j>", function() ntn.NvimTmuxNavigateDown() end},
  {"<c-k>", function() ntn.NvimTmuxNavigateUp() end},
})
