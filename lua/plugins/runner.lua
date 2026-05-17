return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = {
      "ToggleTerm",
      "TermExec",
    },
    event = "VeryLazy",
    opts = {
      close_on_exit = false,
      direction = "horizontal",
      persist_size = true,
      shade_terminals = false,
      size = 15,
      start_in_insert = false,
    },
  },
}
