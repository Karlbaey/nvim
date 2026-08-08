# Repository Guidelines

## Project Structure & Module Organization
This repository is a personal Neovim configuration rooted at `init.lua`. Core runtime modules live under `lua/config/`:
- `options.lua` — editor options
- `keymaps.lua` — global keymaps (leader = Space, localleader = `\`)
- `autocmds.lua` — auto commands (filetype indent, treesitter, venv detection)
- `lazy.lua` — bootstraps lazy.nvim, loads plugin specs from `lua/plugins/`
- `lsp.lua` — LSP `on_attach` handler (keymaps: `K`, `gd`, `gr`, `<leader>rn`, etc.)
- `runner.lua` — reusable command runner that resolves venv Python or system executables
- `go.lua` — Go-specific workflows (`<F7>` test, `<F8>` run, `<leader>gt` test-func)
- `python.lua` — Python workflow (run, debug, REPL, test with pytest/unittest)
- `python_venv.lua` — automatic Python venv detection and path resolution
- `markdown.lua` — buffer-local keymaps for markdown preview (`<F5>`, `<leader>mp`)
- `neovide.lua` — Neovide GUI settings (font, cursor/animation); guarded by `vim.g.neovide`

Plugin specs live under `lua/plugins/`, one concern per file: `lsp.lua`, `format.lua`, `treesitter.lua`, `colorscheme.lua`, `dap.lua`, `gitsigns.lua`, `leetcode.lua`, `lualine.lua`, `markdown.lua`, `mini-icons.lua`, `neo-tree.lua`, `rainbow-delimiters.lua`, `runner.lua`, `rust.lua`, `telescope.lua`, `which-key.lua`. Keep version pins in `lazy-lock.json`. Quick user-facing keymap notes go in `shortcut.txt`.

## Build, Test, and Development Commands
- `nvim` starts the config normally for interactive testing.
- `nvim --headless "+Lazy! sync" +qa` installs or updates plugins from the current specs and lockfile.
- `nvim --headless "+TSInstallCore" +qa` installs the configured Tree-sitter parsers.
- `nvim --headless "+checkhealth" +qa` runs Neovim health checks.
- `nvim --headless -i NONE "+lua print(vim.g.colors_name)" +qa` quick startup smoke test for config and colorscheme loading.

## Architecture
- **init.lua** → sets `mapleader`, `maplocalleader`, proxy → loads `config.options`, `config.neovide`, `config.lazy`, `config.keymaps`, `config.autocmds` in order.
- **lazy.lua** → bootstraps `lazy.nvim` if missing, then `require("lazy").setup({ spec = { import = "plugins" } })`.
- **Autocmd dispatch** → `autocmds.lua` sets up filetype-specific indent, calls `config.go.setup_keymaps()`, `config.python.setup_keymaps()`, `config.markdown.setup_keymaps()`, and auto-detects Python venv on BufEnter. Enforces `fileformat=dos` for all normal buffers.
- **Runner** → `runner.lua` builds a shell command per filetype, preferring venv Python or first-found executable. Used by `go.lua` and `python.lua`.
- **LSP** → `lsp.lua`'s `on_attach` is referenced by `plugins/lsp.lua` (mason + lspconfig); enables semantic tokens for gopls.
- **Colorscheme** → Catppuccin Mocha (set in `plugins/colorscheme.lua`).

## Conventions
- Lua with **2-space indentation**; go uses tabs (set via autocmd), Python uses 4-space expandtab.
- Prefer small modules with explicit `local M = {}` exports.
- Name config modules by responsibility (`config.go`, `config.runner`); plugin specs go in `lua/plugins/` by concern.
- **CRLF line endings** enforced via `.gitattributes` (`* text=auto eol=crlf`) and `fileformat=dos` autocmd. Do not convert to LF.
- Avoid unrelated formatting churn.
- `reasonix.toml` at root allows `research` permission for the agent.

## Notes
（留空用于后续补充）