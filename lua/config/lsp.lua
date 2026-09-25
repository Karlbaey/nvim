local M = {}

function M.on_attach(client, bufnr)
  if client.name == "gopls" then
    vim.lsp.semantic_tokens.enable(true, {
      bufnr = bufnr,
    })
  end

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = bufnr,
      desc = desc,
      silent = true,
    })
  end

  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "gr", vim.lsp.buf.references, "Show references")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
end

return M
