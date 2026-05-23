return {
  {
    "yelog/marklive.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
    config = function(_, opts)
      require("marklive").setup(opts)
    end,
  },
}
