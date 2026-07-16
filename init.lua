vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.network_proxy = "http://127.0.0.1:10808"

require("config.options")
require("config.neovide")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
