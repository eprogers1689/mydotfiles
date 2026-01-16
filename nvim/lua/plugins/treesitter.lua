return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter").setup({
        ensure_installed = {
          "bash", "c", "css", "dockerfile", "go", "gomod",
          "html", "javascript", "json", "lua", "luadoc",
          "markdown", "markdown_inline", "python", "query",
          "regex", "rust", "toml", "tsx", "typescript",
          "vim", "vimdoc", "yaml",
        },
        sync_install = false,
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
