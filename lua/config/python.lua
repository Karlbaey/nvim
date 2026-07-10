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

local function get_buffer_dir(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path ~= "" then
    return vim.fs.dirname(vim.fs.normalize(path))
  end

  return vim.fn.getcwd()
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

local function get_python_command(bufnr)
  -- Prefer venv Python when available
  local venv_cmd = require("config.python_venv").get_python_command(bufnr)
  if venv_cmd then
    return venv_cmd
  end

  if vim.fn.executable("python3") == 1 then
    return "python3"
  end
  return "python"
end

local function run_command(command, cwd)
  require("config.runner").execute(command, { cwd = cwd })
end

local function get_dap()
  local ok, dap = pcall(require, "dap")
  if not ok then
    warn("nvim-dap is not available yet. Run :Lazy sync first.")
    return nil
  end

  return dap
end

local function get_dap_python()
  local ok, dap_python = pcall(require, "dap-python")
  if not ok then
    warn("nvim-dap-python is not available yet. Run :Lazy sync first.")
    return nil
  end

  return dap_python
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

  local python_cmd = get_python_command(bufnr)
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

  local python_cmd = get_python_command(0)
  run_command(python_cmd .. " -c " .. vim.fn.shellescape(code), vim.fn.getcwd())
end

function M.open_repl()
  if not ensure_python() then
    return
  end

  local python_cmd = get_python_command(0)
  vim.cmd("TermExec cmd='" .. python_cmd .. "'")
end

local function get_pytest_command(bufnr, file_path)
  -- Use venv Python to run pytest module so we pick up venv-installed pytest
  local venv_cmd = require("config.python_venv").get_python_command(bufnr)
  if venv_cmd then
    return venv_cmd .. " -m pytest " .. vim.fn.shellescape(file_path) .. " -v"
  end

  -- Fallback: system pytest
  if vim.fn.executable("pytest") ~= 1 then
    warn("pytest not found in PATH. Install it with: pip install pytest")
    return nil
  end

  return "pytest " .. vim.fn.shellescape(file_path) .. " -v"
end

function M.run_pytest_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local path = get_buffer_path(bufnr)
  if not path or not write_if_modified(bufnr) then
    return
  end

  local cmd = get_pytest_command(bufnr, path)
  if cmd then
    run_command(cmd, vim.fn.getcwd())
  end
end

function M.run_pytest_function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local path = get_buffer_path(bufnr)
  if not path or not write_if_modified(bufnr) then
    return
  end

  local function_name = vim.fn.expand("<cword>")
  if not (function_name:match("^test_") or function_name:match("^Test")) then
    warn("Cursor is not on a test function (must start with 'test_' or 'Test')")
    return
  end

  local cmd = get_pytest_command(bufnr, path .. "::" .. function_name)
  if cmd then
    run_command(cmd, vim.fn.getcwd())
  end
end

function M.debug_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local dap = get_dap()
  local path = get_buffer_path(bufnr)
  if not dap or not path or not write_if_modified(bufnr) then
    return
  end

  local launch_config = {
    type = "python",
    request = "launch",
    name = "Debug current file",
    program = path,
    cwd = vim.fn.getcwd(),
    console = "integratedTerminal",
    justMyCode = true,
  }

  -- Point debugpy at the venv Python so it resolves venv packages
  local venv_path = require("config.python_venv").get_python_path(bufnr)
  if venv_path then
    launch_config.python = venv_path
  end

  dap.run(launch_config)
end

function M.debug_test_method(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local dap_python = get_dap_python()
  local path = get_buffer_path(bufnr)
  if not dap_python or not path or not write_if_modified(bufnr) then
    return
  end

  dap_python.test_method()
end

function M.toggle_breakpoint()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.toggle_breakpoint()
end

function M.continue_debug()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.continue()
end

function M.step_over()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.step_over()
end

function M.step_into()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.step_into()
end

function M.step_out()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.step_out()
end

function M.open_debug_repl()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.repl.open()
end

function M.terminate_debug()
  local dap = get_dap()
  if not dap then
    return
  end

  dap.terminate()
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

local function restart_pyright()
  if not vim.lsp or not vim.lsp.enable then
    return
  end

  pcall(vim.lsp.enable, "pyright", false)
  vim.defer_fn(function()
    pcall(vim.lsp.enable, "pyright", true)
  end, 200)
end

local function notify_pyright_settings()
  local pyright_settings = require("config.python_venv").pyright_settings()
  if not pyright_settings then
    return
  end

  for _, client in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, pyright_settings)
    client:notify("workspace/didChangeConfiguration", {
      settings = client.config.settings,
    })
  end
end

function M.activate_venv(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local venv = require("config.python_venv").activate(get_buffer_dir(bufnr))
  if not venv then
    warn("Python virtual environment not found. Expected .venv/venv, VIRTUAL_ENV, or UV_PROJECT_ENVIRONMENT.")
    return
  end

  notify_pyright_settings()
  restart_pyright()
  vim.notify(("Python venv activated: %s"):format(venv.venv_dir), vim.log.levels.INFO)
end

function M.deactivate_venv()
  require("config.python_venv").deactivate()
  restart_pyright()
  vim.notify("Python venv deactivated.", vim.log.levels.INFO)
end

function M.setup_commands()
  if M._commands_created then
    return
  end

  M._commands_created = true

  vim.api.nvim_create_user_command("PythonVenvActivate", function()
    M.activate_venv()
  end, {
    desc = "Activate the nearest Python virtual environment",
  })

  vim.api.nvim_create_user_command("PythonVenvDeactivate", function()
    M.deactivate_venv()
  end, {
    desc = "Deactivate the active Python virtual environment",
  })
end

function M.setup_keymaps(bufnr)
  if vim.b[bufnr].python_workflow_keymaps then
    return
  end

  vim.b[bufnr].python_workflow_keymaps = true
  M.setup_commands()

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

  map("n", "<F7>", function()
    M.run_pytest_file(bufnr)
  end, "Python: run pytest on file")

  map("n", "<F8>", function()
    M.run_pytest_function(bufnr)
  end, "Python: run pytest on function")

  map("n", "<leader>pi", function()
    M.organize_imports(bufnr)
  end, "Python: organize imports")

  map("n", "<leader>pr", function()
    M.open_repl()
  end, "Python: open REPL")

  map("n", "<leader>ve", function()
    M.activate_venv(bufnr)
  end, "Python: activate venv")

  map("n", "<leader>+ve", function()
    M.activate_venv(bufnr)
  end, "Python: activate venv")

  map("n", "<F9>", function()
    M.toggle_breakpoint()
  end, "Python: toggle breakpoint")

  map("n", "<F10>", function()
    M.continue_debug()
  end, "Python: start or continue debugging")

  map("n", "<F11>", function()
    M.step_into()
  end, "Python: step into")

  map("n", "<F12>", function()
    M.step_over()
  end, "Python: step over")

  map("n", "<leader>pd", function()
    M.debug_file(bufnr)
  end, "Python: debug current file")

  map("n", "<leader>pt", function()
    M.debug_test_method(bufnr)
  end, "Python: debug nearest pytest test")

  map("n", "<leader>pc", function()
    M.continue_debug()
  end, "Python: continue debugging")

  map("n", "<leader>pb", function()
    M.toggle_breakpoint()
  end, "Python: toggle breakpoint")

  map("n", "<leader>po", function()
    M.step_over()
  end, "Python: step over")

  map("n", "<leader>pn", function()
    M.step_into()
  end, "Python: step into")

  map("n", "<leader>pO", function()
    M.step_out()
  end, "Python: step out")

  map("n", "<leader>pp", function()
    M.open_debug_repl()
  end, "Python: open DAP REPL")

  map("n", "<leader>px", function()
    M.terminate_debug()
  end, "Python: terminate debug session")
end

return M
