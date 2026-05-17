local map = vim.keymap.set

map("n", "<F5>", function()
  require("config.runner").run_current_file()
end, { desc = "Run current file" })

map("n", "<F6>", function()
  local ok, conform = pcall(require, "conform")
  if not ok then
    vim.notify("conform.nvim is not available yet. Run :Lazy sync first.", vim.log.levels.WARN)
    return
  end

  conform.format({
    async = true,
    lsp_fallback = true,
  })
end, { desc = "Format current file" })

map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
