return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local languages = {
        "go",
        "javascript",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "query",
      }

      local function setup_proxy_env()
        local proxy = vim.g.network_proxy
        if type(proxy) == "string" and proxy ~= "" then
          proxy = {
            http = proxy,
            https = proxy,
            all = proxy,
          }
        elseif type(proxy) ~= "table" then
          return
        end

        local function set_proxy(name, value)
          if type(value) == "string" and value ~= "" then
            vim.env[name] = value
            vim.env[name:lower()] = value
          end
        end

        set_proxy("ALL_PROXY", proxy.all)
        set_proxy("HTTPS_PROXY", proxy.https or proxy.all)
        set_proxy("HTTP_PROXY", proxy.http or proxy.https or proxy.all)
        set_proxy("NO_PROXY", proxy.no_proxy)
      end

      local function setup_windows_curl()
        if vim.fn.has("win32") ~= 1 or vim.fn.executable("curl") ~= 1 then
          return
        end

        local curl_home = vim.fs.joinpath(vim.fn.stdpath("data"), "curl")
        local ok = pcall(vim.fn.mkdir, curl_home, "p")
        if not ok then
          return
        end

        local curlrc = { "ssl-no-revoke" }
        local proxy = vim.env.HTTPS_PROXY or vim.env.ALL_PROXY or vim.env.HTTP_PROXY
        local no_proxy = vim.env.NO_PROXY or vim.env.no_proxy
        if type(proxy) == "string" and proxy ~= "" then
          table.insert(curlrc, "proxy = " .. proxy)
        end
        if type(no_proxy) == "string" and no_proxy ~= "" then
          table.insert(curlrc, "noproxy = " .. no_proxy)
        end

        for _, filename in ipairs({ "_curlrc", ".curlrc" }) do
          ok = pcall(vim.fn.writefile, curlrc, vim.fs.joinpath(curl_home, filename))
          if not ok then
            return
          end
        end

        vim.env.CURL_HOME = curl_home
      end

      setup_proxy_env()
      setup_windows_curl()

      if vim.fn.has("win32") == 1 and vim.fn.executable("cl.exe") ~= 1 then
        if vim.fn.executable("gcc") == 1 and not vim.env.CC then
          vim.env.CC = "gcc"
        end

        if vim.fn.executable("g++") == 1 and not vim.env.CXX then
          vim.env.CXX = "g++"
        end
      end

      local nvim_treesitter = require("nvim-treesitter")

      nvim_treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
        indent = {
          enable = true,
        },
      })

      vim.api.nvim_create_user_command("TSInstallCore", function()
        if vim.fn.executable("tree-sitter") ~= 1 then
          vim.notify(
            "tree-sitter CLI is missing from PATH. Install it first, then rerun :TSInstallCore.",
            vim.log.levels.ERROR
          )
          return
        end

        local install = nvim_treesitter.install(languages, { summary = true })
        if install and install.wait and #vim.api.nvim_list_uis() == 0 then
          install:wait(300000)
        end
      end, {
        desc = "Install configured Tree-sitter parsers",
      })
    end,
  },
}
