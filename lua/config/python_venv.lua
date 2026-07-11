local M = {}

-- Active venv set by user via <leader>ve (nil = no venv manually activated)
M._active_venv = nil
M._active_bin_dir = nil
local original_env = nil

-- Cache: bufnr → { python_path, venv_name, venv_dir } or false (scanned but not found)
local cache = {}

local is_windows = vim.fn.has("win32") == 1
local path_separator = is_windows and ";" or ":"
local venv_names = { ".venv", "venv" }
local project_markers = {
  ".git",
  "pyrightconfig.json",
  "pyproject.toml",
  "uv.lock",
  ".python-version",
  "requirements.txt",
  "Pipfile",
  "setup.py",
  "setup.cfg",
  ".gitignore",
}

-- ---------------------------------------------------------------------------
-- Project root detection
-- ---------------------------------------------------------------------------

local function normalize_dir(dir)
  if not dir or dir == "" or vim.fn.isdirectory(dir) ~= 1 then
    return nil
  end
  return vim.fs.normalize(vim.fn.fnamemodify(dir, ":p"))
end

local function find_project_root(source_dir)
  if not source_dir or source_dir == "" or vim.fn.isdirectory(source_dir) ~= 1 then
    return nil
  end

  local ok, root = pcall(vim.fs.root, source_dir, project_markers)
  if ok and root then
    return vim.fs.normalize(root)
  end

  return nil
end

local function git_toplevel(source_dir)
  if not source_dir or source_dir == "" or vim.fn.isdirectory(source_dir) ~= 1 then
    return nil
  end

  local output = vim.fn.systemlist({ "git", "-C", source_dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not output or not output[1] or output[1] == "" then
    return nil
  end

  return vim.fs.normalize(output[1])
end

-- ---------------------------------------------------------------------------
-- Venv scanning
-- ---------------------------------------------------------------------------

local function is_python_executable(path)
  -- executable() with absolute path works on both Windows and Unix
  return vim.fn.executable(path) == 1
end

local function venv_from_dir(venv_dir, venv_name)
  venv_dir = normalize_dir(venv_dir)
  if not venv_dir then
    return nil
  end

  local python_bin = vim.fs.joinpath(
    venv_dir,
    is_windows and "Scripts" or "bin",
    is_windows and "python.exe" or "python"
  )
  if is_python_executable(python_bin) then
    return {
      python_path = python_bin,
      venv_name = venv_name or vim.fs.basename(venv_dir),
      venv_dir = venv_dir,
    }
  end
  return nil
end

local function venv_bin_dir(venv)
  return vim.fs.joinpath(venv.venv_dir, is_windows and "Scripts" or "bin")
end

local function comparable_path(path)
  if not path or path == "" then
    return nil
  end

  local normalized = vim.fs.normalize(path)
  return is_windows and normalized:lower() or normalized
end

local function path_without_entries(path_value, entries)
  if not path_value or path_value == "" then
    return {}
  end

  local skip = {}
  for _, entry in ipairs(entries) do
    local key = comparable_path(entry)
    if key then
      skip[key] = true
    end
  end

  local result = {}
  for _, entry in ipairs(vim.split(path_value, path_separator, { plain = true })) do
    local key = comparable_path(entry)
    if entry ~= "" and not skip[key] then
      table.insert(result, entry)
    end
  end

  return result
end

local function apply_env(venv)
  local bin_dir = venv_bin_dir(venv)

  if not original_env then
    original_env = {
      PATH = vim.env.PATH,
      VIRTUAL_ENV = vim.env.VIRTUAL_ENV,
      UV_PROJECT_ENVIRONMENT = vim.env.UV_PROJECT_ENVIRONMENT,
    }
  end

  local path_entries = path_without_entries(vim.env.PATH, { M._active_bin_dir, bin_dir })
  table.insert(path_entries, 1, bin_dir)

  vim.env.PATH = table.concat(path_entries, path_separator)
  vim.env.VIRTUAL_ENV = venv.venv_dir
  vim.env.UV_PROJECT_ENVIRONMENT = venv.venv_dir
  M._active_bin_dir = bin_dir
end

local function restore_env()
  if original_env then
    vim.env.PATH = original_env.PATH
    vim.env.VIRTUAL_ENV = original_env.VIRTUAL_ENV
    vim.env.UV_PROJECT_ENVIRONMENT = original_env.UV_PROJECT_ENVIRONMENT
    original_env = nil
  elseif M._active_bin_dir then
    vim.env.PATH = table.concat(path_without_entries(vim.env.PATH, { M._active_bin_dir }), path_separator)
  end

  M._active_bin_dir = nil
end

local function env_path(name)
  local value = vim.fn.getenv(name)
  if value == nil or value == vim.NIL or value == "" then
    return nil
  end

  return normalize_dir(value)
end

local function detect_env_venv()
  for _, env_name in ipairs({ "VIRTUAL_ENV", "UV_PROJECT_ENVIRONMENT" }) do
    local path = env_path(env_name)
    if path then
      local result = venv_from_dir(path, vim.fs.basename(path))
      if result then
        return result
      end
    end
  end
  return nil
end

local function scan_dir_for_venv(search_dir)
  search_dir = normalize_dir(search_dir)
  if not search_dir then
    return nil
  end

  for _, name in ipairs(venv_names) do
    local result = venv_from_dir(vim.fs.joinpath(search_dir, name), name)
    if result then
      return result
    end
  end
  return nil
end

local function scan_parents_for_venv(start_dir, max_levels)
  start_dir = normalize_dir(start_dir)
  if not start_dir then
    return nil
  end

  local current = start_dir
  for _ = 1, max_levels do
    local result = scan_dir_for_venv(current)
    if result then
      return result
    end

    local parent = vim.fs.dirname(current)
    if parent == current then
      break
    end
    current = parent
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
--- Returns { python_path, venv_name, venv_dir } or nil.
function M.scan_directory(dir)
  return scan_dir_for_venv(dir)
end

--- Robust venv detection for a given directory (no buffer context).
--- Detection order:
---   1. .venv / venv in the given directory and its parents
---   2. Python project root and Git root .venv / venv
---   3. VIRTUAL_ENV / UV_PROJECT_ENVIRONMENT
---   4. cwd and its parents
--- Returns { python_path, venv_name, venv_dir } or nil.
function M.detect_for_dir(dir)
  local start_dir = dir
  if not start_dir or start_dir == "" or vim.fn.isdirectory(start_dir) ~= 1 then
    start_dir = vim.fn.getcwd()
  end
  start_dir = vim.fs.normalize(start_dir)

  local candidates = {
    start_dir,
    find_project_root(start_dir),
    git_toplevel(start_dir),
    vim.fn.getcwd(),
  }

  local seen = {}
  for _, candidate in ipairs(candidates) do
    if candidate and not seen[candidate] then
      seen[candidate] = true
      local result = scan_parents_for_venv(candidate, 10)
      if result then
        return result
      end
    end
  end

  return detect_env_venv()
end

--- Detect the manually-activated virtual environment.
--- No longer auto-scans; only returns a venv if the user has activated one via <leader>ve.
--- Returns { python_path, venv_name, venv_dir } or nil.
function M.detect(bufnr)
  if M._active_venv then
    return M._active_venv
  end
  return nil
end

--- Return existing site-packages paths for a detected venv.
--- This exposes packages installed into `.venv` with `uv pip` to Pyright.
function M.get_site_packages(venv)
  if not venv or not venv.venv_dir then
    return {}
  end

  local paths = {}
  if is_windows then
    local site_packages = vim.fs.joinpath(venv.venv_dir, "Lib", "site-packages")
    if vim.fn.isdirectory(site_packages) == 1 then
      table.insert(paths, site_packages)
    end
    return paths
  end

  local matches = vim.fn.glob(vim.fs.joinpath(venv.venv_dir, "lib", "python*", "site-packages"), true, true)
  for _, site_packages in ipairs(matches) do
    if vim.fn.isdirectory(site_packages) == 1 then
      table.insert(paths, site_packages)
    end
  end

  return paths
end

--- Build Pyright settings for the active venv.
--- Includes site-packages so Pyright sees packages installed with `uv pip`.
function M.pyright_settings(venv)
  venv = venv or M.detect()
  if not venv then
    return nil
  end

  return {
    python = {
      pythonPath = venv.python_path,
      venvPath = vim.fs.dirname(venv.venv_dir),
      venv = venv.venv_name,
      analysis = {
        extraPaths = M.get_site_packages(venv),
      },
    },
  }
end

--- Manually activate a virtual environment found from the given source directory.
--- Sets process env vars, M._active_venv, and vim.g.python_venv_name.
--- Returns { python_path, venv_name, venv_dir } or nil.
function M.activate(source_dir)
  local result = M.detect_for_dir(source_dir)
  if result then
    M._active_venv = result
    apply_env(result)
    vim.g.python_venv_name = result.venv_name
    cache = {}
    return result
  end
  return nil
end

--- Deactivate the currently active virtual environment.
function M.deactivate()
  M._active_venv = nil
  vim.g.python_venv_name = ""
  restore_env()
  cache = {}
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
