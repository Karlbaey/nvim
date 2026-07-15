return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    cmd = "Leet",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      lang = "python3",
      cn = {
        enabled = true,
      },
      storage = {
        home = "E:/leetcode",
        cache = vim.fn.stdpath("cache") .. "/leetcode",
      },
    },
  },
}
