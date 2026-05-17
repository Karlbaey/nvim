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
        python = true,
        typescript = true,
        typescriptreact = true,
      }

      return {
        notify_no_formatters = true,
        formatters_by_ft = {
          go = { "goimports", "gofmt" },
          javascript = { "prettierd" },
          javascriptreact = { "prettierd" },
          lua = { "stylua" },
          python = { "ruff_format" },
          typescript = { "prettierd" },
          typescriptreact = { "prettierd" },
        },
        format_on_save = function(bufnr)
          if not format_filetypes[vim.bo[bufnr].filetype] then
            return
          end

          return {
            lsp_fallback = true,
            timeout_ms = 1000,
          }
        end,
      }
    end,
  },
}
