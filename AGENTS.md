# Repository Guidelines

## Project Structure & Module Organization
This repository is a personal Neovim configuration rooted at `init.lua`. Core runtime modules live under `lua/config/`:
- `options.lua`, `keymaps.lua`, `autocmds.lua` set editor behavior.
- `runner.lua` and `go.lua` hold reusable workflow logic.

Plugin specs live under `lua/plugins/`, usually one concern per file such as `lsp.lua`, `format.lua`, `treesitter.lua`, and `colorscheme.lua`. Keep plugin version pins in `lazy-lock.json`. Design notes and feature specs belong in `docs/superpowers/specs/`. Quick user-facing keymap notes go in `shortcut.txt`.

## Build, Test, and Development Commands
- `nvim` starts the config normally for interactive testing.
- `nvim --headless "+Lazy! sync" +qa` installs or updates plugins from the current specs and lockfile.
- `nvim --headless "+TSInstallCore" +qa` installs the configured Tree-sitter parsers.
- `nvim --headless "+checkhealth" +qa` runs Neovim health checks.
- `nvim --headless -i NONE "+lua print(vim.g.colors_name)" +qa` is a quick startup smoke test for config and colorscheme loading.

## Coding Style & Naming Conventions
Use Lua with 2-space indentation unless filetype-specific logic requires otherwise. Prefer small modules with explicit `local M = {}` exports. Name config modules by responsibility (`config.go`, `config.runner`) and keep plugin specs descriptive and singular by concern. Preserve CRLF line endings: `.gitattributes` and runtime options are set for `dos` files. Avoid unrelated formatting churn.

## Testing Guidelines
There is no dedicated automated test suite. Validate changes with headless startup checks plus targeted manual tests inside Neovim. For example, after editing `lua/config/go.lua`, open a Go buffer and verify `<F7>`, `<F8>`, and `<leader>gt`. When changing plugin specs, rerun `:Lazy sync` and confirm `lazy-lock.json` matches the intended updates only.

## Commit & Pull Request Guidelines
Recent history uses short, direct subjects in either English or Chinese, for example `Add Go workflow design spec` and `修复 gcc 编译错误`. Keep commits focused and imperative, and avoid mixing unrelated config changes. For pull requests, include:
- a brief summary of behavior changes
- affected modules or keymaps
- manual validation steps
- screenshots only when colorscheme or UI behavior changes
