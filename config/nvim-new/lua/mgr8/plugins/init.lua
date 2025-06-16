return {
{ "alexghergh/nvim-tmux-navigation", config = function() require('nvim-tmux-navigation').setup({ }) end },
  "NMAC427/guess-indent.nvim",
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

}
