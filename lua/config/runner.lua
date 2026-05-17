local M = {}

local function first_executable(candidates)
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
end

local function build_command(filetype, filepath)
  local escaped = vim.fn.shellescape(filepath)

  if filetype == "python" then
    local executable = first_executable({ "python", "py" })
    if not executable then
      return nil, "Python runtime not found in PATH. Expected `python` or `py`."
    end
    return executable .. " " .. escaped
  end

  if filetype == "lua" then
    local executable = first_executable({ "lua", "luajit" })
    if not executable then
      return nil, "Lua runtime not found in PATH. Expected `lua` or `luajit`."
    end
    return executable .. " " .. escaped
  end

  if filetype == "javascript" then
    if vim.fn.executable("node") ~= 1 then
      return nil, "Node.js runtime not found in PATH. Expected `node`."
    end
    return "node " .. escaped
  end

  if filetype == "typescript" or filetype == "typescriptreact" or filetype == "javascriptreact" then
    if vim.fn.executable("tsx") ~= 1 then
      return nil, "TypeScript runner not found in PATH. Expected `tsx`."
    end
    return "tsx " .. escaped
  end

  if filetype == "go" then
    if vim.fn.executable("go") ~= 1 then
      return nil, "Go runtime not found in PATH. Expected `go`."
    end
    return "go run " .. escaped
  end

  return nil, "No runner configured for filetype: " .. filetype
end

local function get_terminal()
  local ok, terminal = pcall(require, "toggleterm.terminal")
  if not ok then
    vim.notify("toggleterm.nvim is not available yet. Run :Lazy sync first.", vim.log.levels.WARN)
    return nil
  end

  if not M.runner then
    M.runner = terminal.Terminal:new({
      direction = "horizontal",
      hidden = true,
      close_on_exit = false,
    })
  end

  return M.runner
end

function M.run_current_file()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    vim.notify("Save the current buffer before running it.", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.cmd.write()
  end

  local command, err = build_command(vim.bo.filetype, filepath)
  if not command then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local terminal = get_terminal()
  if not terminal then
    return
  end

  terminal:open()
  terminal:send(command, false)
end

return M
