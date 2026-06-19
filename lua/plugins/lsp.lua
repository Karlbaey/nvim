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
