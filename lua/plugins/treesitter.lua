return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      local parser_install_dir = vim.fn.stdpath("data") .. "/site"
      vim.opt.runtimepath:append(parser_install_dir)
    end,
    config = function()
      local parser_install_dir = vim.fn.stdpath("data") .. "/site"

      require("nvim-treesitter.configs").setup({
        parser_install_dir = parser_install_dir,
        ensure_installed = {
          "go",
          "javascript",
          "lua",
          "python",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "query",
        },
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },
}
