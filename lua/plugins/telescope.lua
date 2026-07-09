return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    keys = {
      { "<leader>ff", "<Cmd>Telescope find_files<CR>",  desc = "Find files" },
      { "<leader>fg", "<Cmd>Telescope live_grep<CR>",   desc = "Live grep" },
      { "<leader>fb", "<Cmd>Telescope buffers<CR>",     desc = "Buffers" },
      { "<leader>fh", "<Cmd>Telescope help_tags<CR>",   desc = "Help tags" },
      { "<leader>fc", "<Cmd>Telescope commands<CR>",    desc = "Commands" },
      { "<leader>fk", "<Cmd>Telescope keymaps<CR>",     desc = "Keymaps" },
    },
    opts = {
      defaults = {
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
        live_grep = {
          additional_args = { "--hidden" },
        },
      },
    },
  },
}