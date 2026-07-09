return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",
      spec = {
        { "<leader>c",  group = "code" },
        { "<leader>d",  group = "diagnostics" },
        { "<leader>f",  group = "find/file" },
        { "<leader>g",  group = "go" },
        { "<leader>h",  group = "git hunk" },
        { "<leader>r",  group = "rename/refactor" },
        { "<leader>x",  group = "trouble/diagnostics" },
      },
      icons = {
        breadcrumb = "»",
        separator = "›",
        group = "+",
      },
      plugins = {
        presets = {
          g = false, -- disables g-prefix help to avoid Neovim built-in gc/gcc overlap
        },
      },
    },
  },
}