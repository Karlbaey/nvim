return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local languages = {
        "go",
        "javascript",
        "lua",
        "python",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "query",
      }

      if vim.fn.has("win32") == 1 and vim.fn.executable("cl.exe") ~= 1 then
        if vim.fn.executable("gcc") == 1 and not vim.env.CC then
          vim.env.CC = "gcc"
        end

        if vim.fn.executable("g++") == 1 and not vim.env.CXX then
          vim.env.CXX = "g++"
        end
      end

      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      vim.api.nvim_create_user_command("TSInstallCore", function()
        require("nvim-treesitter").install(languages, { summary = true })
      end, {
        desc = "Install configured Tree-sitter parsers",
      })
    end,
  },
}
