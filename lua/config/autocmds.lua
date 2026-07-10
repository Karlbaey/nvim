local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("custom_config", { clear = true })
local treesitter_warned = {}

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

autocmd("FileType", {
  group = group,
  pattern = "python",
  callback = function(args)
    vim.opt_local.autoindent = true
    require("config.python").setup_keymaps(args.buf)
  end,
})

autocmd("BufEnter", {
  group = group,
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].filetype == "python" then
      local venv = require("config.python_venv")
      local name = venv.get_venv_name(args.buf)
      vim.g.python_venv_name = name or ""
    else
      vim.g.python_venv_name = ""
    end
  end,
})

autocmd("FileType", {
  group = group,
  pattern = "go",
  callback = function(args)
    require("config.go").setup_keymaps(args.buf)
  end,
})

autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function(args)
    require("config.markdown").setup_keymaps(args.buf)
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

autocmd({ "BufReadPost", "BufNewFile" }, {
  group = group,
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].buftype == "" then
      vim.bo[args.buf].fileformat = "dos"
    end
  end,
})

autocmd("FileType", {
  group = group,
  pattern = {
    "lua",
    "python",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "go",
    "vim",
  },
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if not ok and not treesitter_warned[args.match] then
      treesitter_warned[args.match] = true
      vim.schedule(function()
        vim.notify(
          ("Tree-sitter parser for %s is unavailable. Run :TSInstallCore to install configured parsers."):format(
            args.match
          ),
          vim.log.levels.WARN
        )
      end)
    end

    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
