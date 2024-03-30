local harpoon = require 'harpoon'

-- Window +  better kitty navigation
vim.keymap.set('n', '<C-j>', function()
  if vim.fn.exists ':NvimTmuxNavigateDown' ~= 0 then
    vim.cmd.NvimTmuxNavigateDown()
  else
    vim.cmd.wincmd 'j'
  end
end)

vim.keymap.set('n', '<C-k>', function()
  if vim.fn.exists ':NvimTmuxNavigateUp' ~= 0 then
    vim.cmd.NvimTmuxNavigateUp()
  else
    vim.cmd.wincmd 'k'
  end
end)

vim.keymap.set('n', '<C-l>', function()
  if vim.fn.exists ':NvimTmuxNavigateRight' ~= 0 then
    vim.cmd.NvimTmuxNavigateRight()
  else
    vim.cmd.wincmd 'l'
  end
end)

vim.keymap.set('n', '<C-h>', function()
  if vim.fn.exists ':NvimTmuxNavigateLeft' ~= 0 then
    vim.cmd.NvimTmuxNavigateLeft()
  else
    vim.cmd.wincmd 'h'
  end
end)

vim.keymap.set('n', '<space>', '<nop>', { noremap = true, silent = true })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true })

-- Goto next diagnostic of any severity
vim.keymap.set('n', ']d', function()
  vim.diagnostic.goto_next {}
  vim.api.nvim_feedkeys('zz', 'n', false)
end, { noremap = true, silent = true })

-- Goto previous diagnostic of any severity
vim.keymap.set('n', '[d', function()
  vim.diagnostic.goto_prev {}
  vim.api.nvim_feedkeys('zz', 'n', false)
end, { noremap = true, silent = true })

-- Goto next error diagnostic
vim.keymap.set('n', ']e', function()
  vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
  vim.api.nvim_feedkeys('zz', 'n', false)
end, { noremap = true, silent = true })

-- Goto previous error diagnostic
vim.keymap.set('n', '[e', function()
  vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
  vim.api.nvim_feedkeys('zz', 'n', false)
end, { noremap = true, silent = true })

-- Goto next warning diagnostic
vim.keymap.set('n', ']w', function()
  vim.diagnostic.goto_next { severity = vim.diagnostic.severity.WARN }
  vim.api.nvim_feedkeys('zz', 'n', false)
end, { noremap = true, silent = true })

-- Goto previous warning diagnostic
vim.keymap.set('n', '[w', function()
  vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.WARN }
  vim.api.nvim_feedkeys('zz', 'n', false)
end, { noremap = true, silent = true })

-- Open the diagnostic under the cursor in a float window
vim.keymap.set('n', '<leader>d', function()
  vim.diagnostic.open_float {
    border = 'rounded',
  }
end, { noremap = true, silent = true })

-- Place all dignostics into a qflist
vim.keymap.set('n', '<leader>ld', vim.diagnostic.setqflist, { desc = 'Quickfix [L]ist [D]iagnostics', noremap = true, silent = true })

-- Navigate to next qflist item
vim.keymap.set('n', '<leader>cn', ':cnext<cr>zz', { noremap = true, silent = true })

-- Navigate to previos qflist item
vim.keymap.set('n', '<leader>cp', ':cprevious<cr>zz', { noremap = true, silent = true })

-- Open the qflist
vim.keymap.set('n', '<leader>co', ':copen<cr>zz', { noremap = true, silent = true })

-- Close the qflist
vim.keymap.set('n', '<leader>cc', ':cclose<cr>zz', { noremap = true, silent = true })

-- Press leader f to format
vim.keymap.set('n', '<leader>f', function()
  require('conform').format { async = true, lsp_fallback = true }
end, { desc = 'Format the current buffer', noremap = true, silent = true })

-- -- Diagnostic keymaps
-- vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
-- vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
--
-- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
-- vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [L]ist in [Q]uickfix' })

vim.keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit', noremap = true, silent = true })
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save/Write', noremap = true, silent = true })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode', noremap = true, silent = true })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
-- vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window', noremap = true, silent = true })
-- vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window', noremap = true, silent = true })
-- vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window', noremap = true, silent = true })
-- vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window', noremap = true, silent = true })

-- Map Oil to <leader>e
vim.keymap.set('n', '<leader>e', function()
  require('oil').toggle_float()
end, { noremap = true, silent = true })

-- Center buffer while navigating
vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true, silent = true })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true, silent = true })
vim.keymap.set('n', '{', '{zz', { noremap = true, silent = true })
vim.keymap.set('n', '}', '}zz', { noremap = true, silent = true })
vim.keymap.set('n', 'N', 'Nzz', { noremap = true, silent = true })
vim.keymap.set('n', 'n', 'nzz', { noremap = true, silent = true })
vim.keymap.set('n', 'G', 'Gzz', { noremap = true, silent = true })
vim.keymap.set('n', 'gg', 'ggzz', { noremap = true, silent = true })
vim.keymap.set('n', '<C-i>', '<C-i>zz', { noremap = true, silent = true })
vim.keymap.set('n', '<C-o>', '<C-o>zz', { noremap = true, silent = true })
vim.keymap.set('n', '%', '%zz', { noremap = true, silent = true })
vim.keymap.set('n', '*', '*zz', { noremap = true, silent = true })
vim.keymap.set('n', '#', '#zz', { noremap = true, silent = true })

-- Press 'S' for quick find/replace for the word under the cursor
vim.keymap.set('n', 'S', function()
  local cmd = ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>'
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { noremap = true, silent = true })

-- Open Spectre for global find/replace
vim.keymap.set('n', '<leader>S', function()
  require('spectre').toggle()
end, { noremap = true, silent = true })

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
vim.keymap.set('n', 'L', '$', { noremap = true, silent = true })
vim.keymap.set('n', 'H', '^', { noremap = true, silent = true })

-- Press 'U' for redo
vim.keymap.set('n', 'U', '<C-r>', { noremap = true, silent = true })

-- Harpoon keybinds --
-- Open harpoon ui
vim.keymap.set('n', '<leader>ho', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { noremap = true, silent = true })

-- Add current file to harpoon
vim.keymap.set('n', '<leader>ha', function()
  harpoon:list():append()
end, { noremap = true, silent = true })

-- Remove current file from harpoon
vim.keymap.set('n', '<leader>hr', function()
  harpoon:list():remove()
end, { noremap = true, silent = true })

-- Remove all files from harpoon
vim.keymap.set('n', '<leader>hc', function()
  harpoon:list():clear()
end, { noremap = true, silent = true })

-- Quickly jump to harpooned files
vim.keymap.set('n', '<leader>1', function()
  harpoon:list():select(1)
end, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>2', function()
  harpoon:list():select(2)
end, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>3', function()
  harpoon:list():select(3)
end, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>4', function()
  harpoon:list():select(4)
end, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>5', function()
  harpoon:list():select(5)
end, { noremap = true, silent = true })
