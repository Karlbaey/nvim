return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "debugpy",
        "goimports",
        "gopls",
        "lua-language-server",
        "prettierd",
        "pyright",
        "ruff",
        "stylua",
        "typescript-language-server",
      },
      run_on_start = true,
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
    },
    opts = {
      automatic_installation = true,
      automatic_enable = false,
      ensure_installed = {
        "gopls",
        "lua_ls",
        "pyright",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspLog", "LspRestart", "LspStart", "LspStop" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.general = capabilities.general or {}
      capabilities.general.positionEncodings = { "utf-16" }

      vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
        },
      })

      local function on_attach(client, bufnr)
        if client.name == "gopls" then
          vim.lsp.semantic_tokens.enable(true, {
            bufnr = bufnr,
          })
        end

        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            desc = desc,
            silent = true,
          })
        end

        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "gr", vim.lsp.buf.references, "Show references")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
      end

      local function apply_pyright_venv(config)
        local pyright_settings = require("config.python_venv").pyright_settings()
        if not pyright_settings then
          return false
        end

        config.settings = vim.tbl_deep_extend("force", config.settings or {}, pyright_settings)
        return true
      end

      local python_root_markers = {
        "pyrightconfig.json",
        "pyproject.toml",
        "uv.lock",
        ".python-version",
        "requirements.txt",
        "Pipfile",
        "setup.py",
        "setup.cfg",
        ".venv",
        "venv",
        ".git",
      }

      local function pyright_root_dir(bufnr, on_dir)
        local root = vim.fs.root(bufnr, python_root_markers)
        if root then
          on_dir(root)
          return
        end

        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname ~= "" then
          on_dir(vim.fs.dirname(vim.fs.normalize(bufname)))
        else
          on_dir(vim.fn.getcwd())
        end
      end

      local servers = {
        gopls = {
          settings = {
            gopls = {
              semanticTokens = true,
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
              },
            },
          },
        },
        pyright = {
          root_dir = pyright_root_dir,
          before_init = function(_, config)
            apply_pyright_venv(config)
          end,
          on_new_config = function(config)
            apply_pyright_venv(config)
          end,
          on_init = function(client)
            if apply_pyright_venv(client.config) then
              client:notify("workspace/didChangeConfiguration", {
                settings = client.config.settings,
              })
            end
          end,
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
                diagnosticSeverityOverrides = {
                  reportUnusedImport = "information",
                  reportUnusedVariable = "information",
                },
              },
            },
          },
        },
        ruff = {
          on_attach = function(client, bufnr)
            client.server_capabilities.hoverProvider = false
            on_attach(client, bufnr)
          end,
          settings = {
            organizeImports = true,
            fixAll = true,
          },
        },
        ts_ls = {},
      }

      local server_names = vim.tbl_keys(servers)

      local function lsp_command_names(args)
        if args.args ~= "" then
          return vim.split(args.args, "%s+", { trimempty = true })
        end
        return server_names
      end

      local function complete_lsp_names(arg_lead)
        return vim
          .iter(server_names)
          :filter(function(name)
            return vim.startswith(name, arg_lead)
          end)
          :totable()
      end

      vim.api.nvim_create_user_command("LspStart", function(args)
        vim.lsp.enable(lsp_command_names(args), true)
      end, {
        complete = complete_lsp_names,
        desc = "Start configured LSP clients",
        nargs = "*",
      })

      vim.api.nvim_create_user_command("LspStop", function(args)
        vim.lsp.enable(lsp_command_names(args), false)
      end, {
        complete = complete_lsp_names,
        desc = "Stop configured LSP clients",
        nargs = "*",
      })

      -- server name → filetypes 映射,用于 LspRestart 后重新触发 attach
      local server_filetypes = {
        gopls = { "go" },
        lua_ls = { "lua" },
        pyright = { "python" },
        ruff = { "python" },
        ts_ls = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
      }

      local function relaunch_filetypes(names)
        local fts = {}
        for _, n in ipairs(names) do
          for _, ft in ipairs(server_filetypes[n] or {}) do
            fts[ft] = true
          end
        end
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(b) and fts[vim.bo[b].filetype] then
            local ft = vim.bo[b].filetype
            vim.bo[b].filetype = ""
            vim.bo[b].filetype = ft
          end
        end
      end

      vim.api.nvim_create_user_command("LspRestart", function(args)
        local names = lsp_command_names(args)
        -- nvim 0.12:enable(false) 再 enable(true) 不会让已 attach 过的 buffer 重新
        -- 生成新 client。可靠序列:停用 → 等旧 client detach → 重新启用 → 重触发
        -- 对应 filetype 的 FileType 事件以命中 attach。
        vim.lsp.enable(names, false)
        vim.defer_fn(function()
          vim.wait(2000, function()
            for _, n in ipairs(names) do
              if #vim.lsp.get_clients({ name = n }) > 0 then
                return false
              end
            end
            return true
          end, 50)
          pcall(vim.lsp.enable, names, true)
          vim.schedule(function()
            relaunch_filetypes(names)
          end)
        end, 50)
      end, {
        complete = complete_lsp_names,
        desc = "Restart configured LSP clients",
        nargs = "*",
      })

      vim.api.nvim_create_user_command("LspInfo", function()
        vim.cmd("checkhealth vim.lsp")
      end, {
        desc = "Show Neovim LSP health information",
      })

      vim.api.nvim_create_user_command("LspLog", function()
        vim.cmd.edit(vim.fn.fnameescape(vim.lsp.log.get_filename()))
      end, {
        desc = "Open the Neovim LSP log",
      })

      for server_name, server_config in pairs(servers) do
        vim.lsp.config(server_name, vim.tbl_deep_extend("force", {
          capabilities = capabilities,
          on_attach = on_attach,
        }, server_config))
        vim.lsp.enable(server_name)
      end
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "rafamadriz/friendly-snippets",
      "saadparwaiz1/cmp_luasnip",
      "windwp/nvim-autopairs",
    },
    config = function()
      local cmp = require("cmp")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
      })

      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}
