-- Set leader key to Space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================================
-- MATTJMORRISON-STYLE MAPPINGS
-- ============================================

-- Splits: Leader+\ (vertical), Leader+- (horizontal)
keymap("n", "<leader>\\", "<cmd>vsplit<CR>", { desc = "Vertical split" })
keymap("n", "<leader>-", "<cmd>split<CR>", { desc = "Horizontal split" })

-- Buffer toggle: Leader+Leader (switch to last buffer)
keymap("n", "<leader><leader>", "<C-^>", { desc = "Toggle last buffer" })

-- Config editing: Leader+ev (edit), Leader+sv (source/reload)
keymap("n", "<leader>ev", "<cmd>vsplit $MYVIMRC<CR>", { desc = "Edit config" })
keymap("n", "<leader>sv", "<cmd>source $MYVIMRC<CR>", { desc = "Reload config" })

-- Clear search highlight
keymap("n", "<leader><Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Toggle relative line numbers
keymap("n", "<leader>tn", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative numbers" })

-- Toggle spell check
keymap("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })

-- ============================================
-- WINDOW NAVIGATION (handled by vim-tmux-navigator)
-- These are fallbacks if plugin not loaded
-- ============================================
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ============================================
-- WINDOW RESIZING
-- ============================================
keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- ============================================
-- BUFFER NAVIGATION
-- ============================================
keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- ============================================
-- QUALITY OF LIFE
-- ============================================

-- Better indenting (stay in visual mode)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move lines up/down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Paste without losing register content
keymap("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })

-- Save with sudo
keymap("c", "w!!", "w !sudo tee % > /dev/null", { desc = "Save with sudo" })
