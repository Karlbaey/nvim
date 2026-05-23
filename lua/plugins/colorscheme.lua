return {
  {
    "tanvirtin/monokai.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai").setup({})
      vim.cmd.colorscheme("monokai")
    end,
  },
}
