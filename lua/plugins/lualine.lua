return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_c = {
          "filename",
          {
            function()
              local name = vim.g.python_venv_name
              if name and name ~= "" then
                return "venv:" .. name
              end
              return ""
            end,
            cond = function()
              return vim.bo.filetype == "python"
            end,
            color = { fg = "#a6e22e" },
          },
        },
      },
    },
  },
}