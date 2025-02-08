-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps --

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "[W]rite file" })
keymap.set("n", "<leader>qb", "<cmd>bd<CR>", { desc = "[Q]uit [b]uffer" })
keymap.set("n", "<leader>qa", "<cmd>bufdo bd<CR>", { desc = "[Q]uit [a]ll buffers" })
-- delete single character without copying into register
keymap.set("n", "x", '"_x')

keymap.set("v", ">", ">gv", { desc = "indent " })
keymap.set("v", "<", "<gv", { desc = "outdent " })
