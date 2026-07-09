return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>fe", "<Cmd>Neotree toggle<CR>",    desc = "Toggle file tree" },
      { "<leader>fR", "<Cmd>Neotree reveal<CR>",    desc = "Reveal in file tree" },
    },
    opts = {
      close_if_last_window = true,
      window = {
        position = "left",
        width = 35,
        mappings = {
          ["o"] = "open",
          ["<CR>"] = "open",
        },
      },
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
        },
        follow_current_file = { enabled = true },
      },
    },
  },
}