return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Navigate Left (tmux/vim)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Navigate Down (tmux/vim)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Navigate Up (tmux/vim)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Navigate Right (tmux/vim)" },
    },
  },
}
