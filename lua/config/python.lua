local M = {}

local function warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

local function ensure_python()
  if vim.fn.executable("python") ~= 1 and vim.fn.executable("python3") ~= 1 then
    warn("Python runtime not found in PATH. Expected `python` or `python3`.")
    return false
  end

  return true
end

local function get_buffer_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    warn("Save the current Python buffer before running Python commands.")
    return nil
  end

  return vim.fs.normalize(path)
end

local function write_if_modified(bufnr)
  if not vim.bo[bufnr].modified then
    return true
  end

  local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
    vim.cmd.write()
  end)

  if ok then
    return true
  end

  warn("Failed to save the current buffer: " .. err)
  return false
end

local function get_python_command()
  if vim.fn.executable("python3") == 1 then
    return "python3"
  end
  return "python"
end

local function run_command(command, cwd)
  require("config.runner").execute(command, { cwd = cwd })
end

function M.run_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not ensure_python() then
    return
  end

  local path = get_buffer_path(bufnr)
  if not path or not write_if_modified(bufnr) then
    return
  end

  local python_cmd = get_python_command()
  run_command(python_cmd .. " " .. vim.fn.shellescape(path), vim.fn.getcwd())
end

function M.run_selection()
  if not ensure_python() then
    return
  end

  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local code = table.concat(lines, "\n")

  local python_cmd = get_python_command()
  run_command(python_cmd .. " -c " .. vim.fn.shellescape(code), vim.fn.getcwd())
end

function M.open_repl()
  if not ensure_python() then
    return
  end

  local python_cmd = get_python_command()
  vim.cmd("TermExec cmd='" .. python_cmd .. "'")
end

function M.run_pytest_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if vim.fn.executable("pytest") ~= 1 then
    warn("pytest not found in PATH. Install it with: pip install pytest")
    return
  end

  local path = get_buffer_path(bufnr)
  if not path or not write_if_modified(bufnr) then
    return
  end

  run_command("pytest " .. vim.fn.shellescape(path) .. " -v", vim.fn.getcwd())
end

function M.run_pytest_function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if vim.fn.executable("pytest") ~= 1 then
    warn("pytest not found in PATH. Install it with: pip install pytest")
    return
  end

  local path = get_buffer_path(bufnr)
  if not path or not write_if_modified(bufnr) then
    return
  end

  local function_name = vim.fn.expand("<cword>")
  if function_name:match("^test_") or function_name:match("^Test") then
    run_command("pytest " .. vim.fn.shellescape(path) .. "::" .. function_name .. " -v", vim.fn.getcwd())
  else
    warn("Cursor is not on a test function (must start with 'test_' or 'Test')")
  end
end

function M.organize_imports(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    name = "ruff",
  })

  if #clients == 0 then
    warn("Ruff LSP is not attached to this buffer.")
    return
  end

  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = { "source.organizeImports" },
      diagnostics = vim.diagnostic.get(bufnr),
    },
  })
end

function M.setup_keymaps(bufnr)
  if vim.b[bufnr].python_workflow_keymaps then
    return
  end

  vim.b[bufnr].python_workflow_keymaps = true

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = bufnr,
      desc = desc,
      silent = true,
    })
  end

  map("n", "<F5>", function()
    M.run_file(bufnr)
  end, "Python: run file")

  map("v", "<F5>", function()
    M.run_selection()
  end, "Python: run selection")

  map("n", "<F6>", function()
    M.open_repl()
  end, "Python: open REPL")

  map("n", "<F7>", function()
    M.run_pytest_file(bufnr)
  end, "Python: run pytest on file")

  map("n", "<F8>", function()
    M.run_pytest_function(bufnr)
  end, "Python: run pytest on function")

  map("n", "<leader>pi", function()
    M.organize_imports(bufnr)
  end, "Python: organize imports")
end

return M
