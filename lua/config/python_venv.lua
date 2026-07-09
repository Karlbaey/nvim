local M = {}

-- Cache: bufnr → { python_path, venv_name, venv_dir } or false (scanned but not found)
local cache = {}

local is_windows = vim.fn.has("win32") == 1

-- ---------------------------------------------------------------------------
-- Project root detection
-- ---------------------------------------------------------------------------

local function find_project_root(source_dir)
  -- Try vim.fs.root (Neovim >= 0.10) with common Python project markers
  local ok, root = pcall(vim.fs.root, source_dir, {
    ".git",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    ".gitignore",
  })
  if ok and root then
    return root
  end

  -- Fallback: manual upward search for .git
  local current = source_dir
  for _ = 1, 20 do
    if vim.fn.isdirectory(vim.fs.joinpath(current, ".git")) == 1 then
      return current
    end
    local parent = vim.fs.dirname(current)
    if parent == current then
      break
    end
    current = parent
  end

  return vim.fn.getcwd()
end

-- ---------------------------------------------------------------------------
-- Venv scanning
-- ---------------------------------------------------------------------------

local function is_python_executable(path)
  -- executable() with absolute path works on both Windows and Unix
  return vim.fn.executable(path) == 1
end

local function scan_dir_for_venv(search_dir)
  for _, name in ipairs({ ".venv", "venv" }) do
    local venv_dir = vim.fs.joinpath(search_dir, name)
    if vim.fn.isdirectory(venv_dir) == 1 then
      local python_bin = vim.fs.joinpath(
        venv_dir,
        is_windows and "Scripts" or "bin",
        is_windows and "python.exe" or "python"
      )
      if is_python_executable(python_bin) then
        return {
          python_path = python_bin,
          venv_name = name,
          venv_dir = venv_dir,
        }
      end
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Invalidate cached result for a buffer (call when venv is created/deleted).
function M.invalidate(bufnr)
  cache[bufnr or 0] = nil
end

--- Scan a specific directory for virtual environments.
--- Useful for LSP on_init when no buffer context is available.
--- Returns { python_path, venv_name, venv_dir } or nil.
function M.scan_directory(dir)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    return nil
  end
  return scan_dir_for_venv(dir)
end

--- Detect the virtual environment for a buffer.
--- Returns { python_path, venv_name, venv_dir } or nil.
function M.detect(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if cache[bufnr] ~= nil then
    return cache[bufnr] ~= false and cache[bufnr] or nil
  end

  -- 1. VIRTUAL_ENV env var (e.g. manually activated venv in terminal)
  local venv_env = vim.fn.getenv("VIRTUAL_ENV")
  if venv_env ~= "" and vim.fn.isdirectory(venv_env) == 1 then
    local python_bin = vim.fs.joinpath(
      venv_env,
      is_windows and "Scripts" or "bin",
      is_windows and "python.exe" or "python"
    )
    if is_python_executable(python_bin) then
      local result = {
        python_path = python_bin,
        venv_name = vim.fs.basename(venv_env),
        venv_dir = venv_env,
      }
      cache[bufnr] = result
      return result
    end
  end

  -- 2. Scan project root for .venv / venv directories
  local bufpath = vim.api.nvim_buf_get_name(bufnr)
  if bufpath == "" then
    -- Unsaved buffer: use cwd
    local result = scan_dir_for_venv(vim.fn.getcwd())
    cache[bufnr] = result or false
    return result
  end

  local source_dir = vim.fs.dirname(vim.fs.normalize(bufpath))
  local root = find_project_root(source_dir)
  local result = scan_dir_for_venv(root)

  -- Also check parent of root (some workflows put venv alongside, not inside)
  if not result then
    local parent = vim.fs.dirname(root)
    if parent ~= root then
      result = scan_dir_for_venv(parent)
    end
  end

  cache[bufnr] = result or false
  return result
end

--- Get absolute path to the venv Python executable, or nil.
function M.get_python_path(bufnr)
  local venv = M.detect(bufnr)
  return venv and venv.python_path
end

--- Get a shell-escaped Python command string, ready for terminal use, or nil.
function M.get_python_command(bufnr)
  local python_path = M.get_python_path(bufnr)
  if python_path then
    return vim.fn.shellescape(python_path)
  end
  return nil
end

--- Get virtual environment name for statusline display, or nil.
function M.get_venv_name(bufnr)
  local venv = M.detect(bufnr)
  return venv and venv.venv_name
end

return M