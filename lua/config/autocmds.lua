local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("custom_config", { clear = true })

local indent_by_ft = {
  lua = { shiftwidth = 2, tabstop = 2, softtabstop = 2, expandtab = true },
  javascript = { shiftwidth = 2, tabstop = 2, softtabstop = 2, expandtab = true },
  javascriptreact = { shiftwidth = 2, tabstop = 2, softtabstop = 2, expandtab = true },
  typescript = { shiftwidth = 2, tabstop = 2, softtabstop = 2, expandtab = true },
  typescriptreact = { shiftwidth = 2, tabstop = 2, softtabstop = 2, expandtab = true },
  python = { shiftwidth = 4, tabstop = 4, softtabstop = 4, expandtab = true },
  go = { shiftwidth = 4, tabstop = 4, softtabstop = 4, expandtab = false },
}

autocmd("FileType", {
  group = group,
  pattern = vim.tbl_keys(indent_by_ft),
  callback = function(args)
    local rules = indent_by_ft[args.match]
    if not rules then
      return
    end

    for option, value in pairs(rules) do
      vim.opt_local[option] = value
    end
  end,
})

autocmd("TermOpen", {
  group = group,
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})
