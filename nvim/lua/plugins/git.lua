return {
  -- Gitsigns: git decorations
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local o = { buffer = bufnr }

        vim.keymap.set("n", "]h", gs.next_hunk, o)
        vim.keymap.set("n", "[h", gs.prev_hunk, o)
        vim.keymap.set("n", "<leader>hs", gs.stage_hunk, o)
        vim.keymap.set("n", "<leader>hr", gs.reset_hunk, o)
        vim.keymap.set("n", "<leader>hS", gs.stage_buffer, o)
        vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, o)
        vim.keymap.set("n", "<leader>hR", gs.reset_buffer, o)
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk, o)
        vim.keymap.set("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, o)
        vim.keymap.set("n", "<leader>hd", gs.diffthis, o)
      end,
    },
  },

  -- Fugitive: git commands
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gstatus", "Gblame", "Gpush", "Gpull", "Gdiff" },
    keys = {
      { "<leader>gg", "<cmd>Git<CR>", desc = "Git status (fugitive)" },
      { "<leader>gb", "<cmd>Git blame<CR>", desc = "Git blame" },
    },
  },

  -- Diffview: diff viewer
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview open" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
    },
  },
}
