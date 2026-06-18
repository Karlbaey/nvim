local M = {}

function M.setup_keymaps(bufnr)
  if vim.b[bufnr].markdown_preview_keymaps then
    return
  end

  vim.b[bufnr].markdown_preview_keymaps = true

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, {
      buffer = bufnr,
      desc = desc,
      silent = true,
    })
  end

  map("<F5>", "<Cmd>RenderMarkdown buf_toggle<CR>", "Markdown: toggle live render")
  map("<leader>mp", "<Cmd>RenderMarkdown buf_toggle<CR>", "Markdown: toggle live render")
end

return M
