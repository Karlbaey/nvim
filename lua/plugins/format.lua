return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    opts = function()
      local format_filetypes = {
        go = true,
        javascript = true,
        javascriptreact = true,
        lua = true,
        markdown = true,
        python = true,
      }

      return {
        notify_no_formatters = true,
        formatters_by_ft = {
          go = { "goimports" },
          javascript = { "prettierd" },
          javascriptreact = { "prettierd" },
          lua = { "stylua" },
          markdown = { "prettierd" },
          python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
          typescript = { "prettierd" },
          typescriptreact = { "prettierd" },
        },
        format_on_save = function(bufnr)
          local filetype = vim.bo[bufnr].filetype
          if not format_filetypes[filetype] then
            return
          end

          return {
            lsp_fallback = true,
            timeout_ms = filetype == "go" and 5000 or 1000,
          }
        end,
      }
    end,
  },
}
