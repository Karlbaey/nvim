# Go Workflow Design

## Goal

Expand the existing Neovim configuration into a complete Go editing workflow without introducing a separate Go plugin stack or changing the current global run and format behavior.

## Scope

- Keep the current global `F5` run flow and `F6` format flow unchanged.
- Add Go-specific buffer-local keymaps that only exist in `filetype=go` buffers.
- Support common Go tasks:
  - test the current package
  - test the current test function
  - test the whole module with `go test ./...`
  - run the current package with `go run .`
  - switch between source and `*_test.go`
  - organize imports through `gopls`
- Reuse the existing terminal runner, LSP, formatting, and file layout patterns.

## Non-Goals

- Replacing the current runner with a Go-specific plugin.
- Adding a heavyweight Go workflow plugin such as `go.nvim`.
- Reworking the global keymap layout away from `F5` and `F6`.
- Adding debugging, DAP integration, or test UI windows in this change.

## Current State

- `gopls`, `goimports`, and Go Treesitter support are already configured.
- `conform.nvim` already formats Go using `goimports` and `gofmt`.
- `F5` already runs the current file with `go run <current file>`.
- `F6` already formats the current buffer globally.
- The current runner module already manages a reusable ToggleTerm terminal.
- Keymaps are currently mostly global, with no Go-only hotkey layer.

## Proposed Approach

### Architecture

Keep the existing split between `lua/config` helper modules and `lua/plugins` plugin specs.

Add a Go-specific helper module that owns Go workflow logic and buffer-local keymap registration. Keep general terminal execution in the existing runner module so Go features reuse the same terminal behavior as the other languages.

### Go Keymaps

Add the following Go-only mappings when a Go buffer opens:

- `<F7>`: run `go test` in the current file's package directory
- `<F8>`: run the test, benchmark, or example function under the cursor
- `<leader>ga`: run `go test ./...` from the detected module root
- `<leader>gr`: run `go run .` from the current package directory
- `<leader>gt`: switch between `foo.go` and `foo_test.go`
- `<leader>gi`: request organize imports / Go code action through `gopls`

These mappings must be buffer-local so they do not exist in non-Go buffers.

### Runner Integration

Extend the existing runner module with a small command execution entry point that:

- reuses the current bottom terminal
- optionally accepts a working directory
- opens the terminal before sending the command

Go workflow commands should call this shared entry point instead of creating a second terminal implementation.

### Go Workflow Module

Create a new `lua/config/go.lua` module responsible for:

- finding the current package directory
- finding the nearest `go.mod` root
- extracting the current Go test function name from the cursor position
- switching between source and test file names
- sending Go commands through the shared runner
- applying Go organize-imports actions through LSP
- registering Go buffer-local keymaps

### LSP Behavior

Keep `gopls` as the single Go LSP backend.

The design allows small `gopls` setting improvements if needed, but does not change the broader LSP architecture. Go import organization should prefer the LSP path instead of shelling out directly, so the editor behavior stays consistent with the current code action model.

## File Changes

- `lua/config/runner.lua`
  - add a reusable command execution helper with optional working directory support
- `lua/config/go.lua`
  - new Go-specific workflow module
- `lua/config/autocmds.lua`
  - register a `FileType go` autocmd that installs the buffer-local Go mappings
- `lua/plugins/lsp.lua`
  - keep `gopls` and optionally add small Go-specific settings if required
- `shortcut.txt`
  - add a dedicated Go section for Go-only mappings
  - document each Go mapping and clarify that they are buffer-local

## Data Flow

1. User opens a Go file.
2. A `FileType go` autocmd runs and registers Go buffer-local mappings for that buffer only.
3. When the user triggers a Go mapping, the Go helper resolves the needed context:
   - package directory for package run/test
   - module root for `go test ./...`
   - current function name for single-test execution
   - sibling file path for source/test switching
4. The Go helper calls the shared runner execution helper or the LSP code-action path.
5. The shared runner opens the existing terminal and runs the command in the requested directory.

## Error Handling

- If `go` is not executable, show a clear `vim.notify` warning and do nothing else.
- If no `go.mod` root is found for module-wide tests, fall back to a warning instead of guessing another root.
- If `<F8>` is used outside `Test*`, `Benchmark*`, or `Example*`, show a targeted warning and do not run a package-wide test by accident.
- If a paired source or test file does not exist, notify instead of creating a new file automatically.
- If `gopls` is unavailable for organize imports, notify explicitly rather than failing silently.
- All Go-specific behavior must remain buffer-local to prevent non-Go regressions.

## Testing

- Start Neovim and open a `.go` file.
- Confirm the new Go mappings are available only in that Go buffer.
- Open a non-Go buffer and confirm those Go mappings are absent.
- Use `<F7>` and verify `go test` runs in the current package directory.
- Use `<F8>` on a `Test*`, `Benchmark*`, and `Example*` function and verify precise execution.
- Use `<F8>` outside a supported function and verify a warning is shown.
- Use `<leader>ga` and verify `go test ./...` runs from the module root.
- Use `<leader>gr` and verify `go run .` runs from the current package directory.
- Use `<leader>gt` on files with and without a sibling test file and verify both success and warning paths.
- Use `<leader>gi` and verify imports are organized through LSP when `gopls` is attached.
- Recheck that existing `F5`, `F6`, and non-Go language workflows still behave as before.

## Risks

- Single-test execution depends on correctly identifying the current Go function from buffer context. The implementation should stay conservative and refuse to run when uncertain.
- Module root detection can fail in unusual workspace layouts. The design intentionally prefers explicit warnings over fuzzy fallback behavior.
- Buffer-local key registration must be attached to the right autocmd event to avoid duplicate mappings.

## Recommendation

Implement the Go workflow as a thin Go-specific layer on top of the existing runner and LSP modules. This keeps the setup consistent with the current configuration, avoids redundant plugin ecosystems, and adds the requested Go-only hotkeys without changing the editor's global behavior.
