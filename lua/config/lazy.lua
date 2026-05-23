local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

if not uv.fs_stat(lazypath) then
  if vim.env.SKIP_LAZY_BOOTSTRAP == "1" then
    return
  end

  if vim.fn.executable("git") ~= 1 then
    error("git is required to bootstrap lazy.nvim")
  end

  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. out)
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  rocks = {
    enabled = false,
  },
  change_detection = {
    notify = false,
  },
  install = {
    colorscheme = { "monokai", "habamax" },
  },
})
