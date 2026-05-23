local uv = vim.uv or vim.loop

local M = {}

local function warn(message)
  vim.notify(message, vim.log.levels.WARN)
end

local function is_file(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function ensure_go()
  if vim.fn.executable("go") ~= 1 then
    warn("Go runtime not found in PATH. Expected `go`.")
    return false
  end

  return true
end

local function get_buffer_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    warn("Save the current Go buffer before running Go commands.")
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

local function get_package_dir(bufnr)
  local path = get_buffer_path(bufnr)
  if not path then
    return nil
  end

  return vim.fs.dirname(path)
end

local function get_module_root(bufnr)
  local package_dir = get_package_dir(bufnr)
  if not package_dir then
    return nil
  end

  local go_mod = vim.fs.find("go.mod", {
    path = package_dir,
    upward = true,
  })[1]

  if not go_mod then
    warn("No go.mod found above the current buffer.")
    return nil
  end

  return vim.fs.dirname(go_mod)
end

local function strip_line_noise(line)
  local cleaned = line:gsub("//.*", "")
  cleaned = cleaned:gsub([["([^"\\]|\\.)*"]], '""')
  cleaned = cleaned:gsub("[']([^'\\]|\\.)*[']", "''")
  cleaned = cleaned:gsub("`[^`]*`", "``")
  return cleaned
end

local function get_function_name_fallback(bufnr)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor_line, false)
  local current_name
  local brace_depth = 0
  local seen_body = false

  for index, line in ipairs(lines) do
    if not current_name then
      current_name = line:match("^%s*func%s+([%a_][%w_]*)%s*%(")
      if current_name then
        brace_depth = 0
        seen_body = false
      end
    end

    if current_name and index == cursor_line then
      return current_name
    end

    if current_name then
      local cleaned = strip_line_noise(line)
      local opens = select(2, cleaned:gsub("{", ""))
      local closes = select(2, cleaned:gsub("}", ""))

      if opens > 0 then
        seen_body = true
      end

      brace_depth = brace_depth + opens - closes
      if seen_body and brace_depth <= 0 then
        current_name = nil
        brace_depth = 0
        seen_body = false
      end
    end
  end
end

local function get_function_name_at_cursor(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
  if ok and parser then
    parser:parse(true)

    local cursor = vim.api.nvim_win_get_cursor(0)
    local node = vim.treesitter.get_node({
      bufnr = bufnr,
      pos = { cursor[1] - 1, cursor[2] },
    })

    while node do
      if node:type() == "function_declaration" then
        local name_node = node:field("name")[1]
        if name_node then
          return vim.treesitter.get_node_text(name_node, bufnr)
        end

        break
      end

      node = node:parent()
    end
  end

  return get_function_name_fallback(bufnr)
end

local function get_test_target(bufnr)
  local name = get_function_name_at_cursor(bufnr)
  if not name then
    return nil, nil, "Place the cursor inside a Go Test*, Benchmark*, or Example* function."
  end

  if name:match("^Test[%w_]+$") then
    return name, "test"
  end

  if name:match("^Benchmark[%w_]+$") then
    return name, "benchmark"
  end

  if name:match("^Example[%w_]+$") then
    return name, "example"
  end

  return nil, nil, "Current Go function is not a Test*, Benchmark*, or Example*."
end

local function run_command(command, cwd)
  require("config.runner").execute(command, { cwd = cwd })
end

function M.test_package(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not ensure_go() then
    return
  end

  local package_dir = get_package_dir(bufnr)
  if not package_dir or not write_if_modified(bufnr) then
    return
  end

  run_command("go test", package_dir)
end

function M.test_current_target(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not ensure_go() then
    return
  end

  local package_dir = get_package_dir(bufnr)
  if not package_dir or not write_if_modified(bufnr) then
    return
  end

  local name, kind, err = get_test_target(bufnr)
  if not name then
    warn(err)
    return
  end

  if kind == "benchmark" then
    run_command(
      "go test -run " .. vim.fn.shellescape("^$") .. " -bench " .. vim.fn.shellescape("^" .. name .. "$"),
      package_dir
    )
    return
  end

  run_command("go test -run " .. vim.fn.shellescape("^" .. name .. "$"), package_dir)
end

function M.test_module(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not ensure_go() then
    return
  end

  local module_root = get_module_root(bufnr)
  if not module_root or not write_if_modified(bufnr) then
    return
  end

  run_command("go test ./...", module_root)
end

function M.run_package(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not ensure_go() then
    return
  end

  local package_dir = get_package_dir(bufnr)
  if not package_dir or not write_if_modified(bufnr) then
    return
  end

  run_command("go run .", package_dir)
end

function M.switch_source_and_test(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local path = get_buffer_path(bufnr)
  if not path then
    return
  end

  local target
  if path:sub(-8) == "_test.go" then
    target = path:sub(1, -9) .. ".go"
  elseif path:sub(-3) == ".go" then
    target = path:sub(1, -4) .. "_test.go"
  else
    warn("Current buffer is not a Go source file.")
    return
  end

  if not is_file(target) then
    warn("Paired Go file not found: " .. vim.fs.basename(target))
    return
  end

  if not write_if_modified(bufnr) then
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(target))
end

function M.organize_imports(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    name = "gopls",
  })

  if #clients == 0 then
    warn("gopls is not attached to this buffer, so organize imports is unavailable.")
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
  if vim.b[bufnr].go_workflow_keymaps then
    return
  end

  vim.b[bufnr].go_workflow_keymaps = true

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, {
      buffer = bufnr,
      desc = desc,
      silent = true,
    })
  end

  map("<F7>", function()
    M.test_package(bufnr)
  end, "Go: test package")

  map("<F8>", function()
    M.test_current_target(bufnr)
  end, "Go: test current target")

  map("<leader>ga", function()
    M.test_module(bufnr)
  end, "Go: test module")

  map("<leader>gr", function()
    M.run_package(bufnr)
  end, "Go: run package")

  map("<leader>gt", function()
    M.switch_source_and_test(bufnr)
  end, "Go: switch source/test")

  map("<leader>gi", function()
    M.organize_imports(bufnr)
  end, "Go: organize imports")
end

return M
