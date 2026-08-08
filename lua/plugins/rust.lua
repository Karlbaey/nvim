return {
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false,
    init = function()
      local lsp = require("config.lsp")
      vim.g.rustaceanvim = {
        server = {
          on_attach = lsp.on_attach,
          default_settings = {
            ["rust-analyzer"] = {
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              cargo = {
                features = "all",
              },
              inlayHints = {
                bindingModeHints = { enable = false },
                chainingHints = { enable = true },
                closureCaptureHints = { enable = true },
                closureReturnTypeHints = { enable = "always" },
                lifetimeElisionHints = { enable = "never", useParameterNames = false },
                expressionAdjustmentHints = { enable = false },
                implicitDrops = { enable = false },
                parameterNames = { enable = true },
                rangeExclusiveHints = { enable = false },
                renderColons = true,
                typeHints = { enable = true },
              },
            },
          },
        },
      }
    end,
    keys = {
      { "<leader>rx", "<cmd>RustLsp expandMacro<cr>", desc = "Expand macro recursively" },
      { "<leader>rm", "<cmd>RustLsp moveItem up<cr>", desc = "Move item up" },
      { "<leader>rM", "<cmd>RustLsp moveItem down<cr>", desc = "Move item down" },
      { "<leader>rj", "<cmd>RustLsp joinLines<cr>", desc = "Join lines (Rust-aware)" },
      { "<leader>rh", "<cmd>RustLsp hover actions<cr>", desc = "Hover actions" },
      { "<leader>rr", "<cmd>RustLsp runnables<cr>", desc = "Runnables (cargo run/test)" },
      { "<leader>rd", "<cmd>RustLsp debuggables<cr>", desc = "Debuggables (codelldb)" },
      { "<leader>re", "<cmd>RustLsp explainError<cr>", desc = "Explain error (rustc --explain)" },
      { "<leader>rg", "<cmd>RustLsp relatedDiagnostics<cr>", desc = "Related diagnostics" },
    },
  },
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      src = {
        insert_crate = false,
      },
      popup = {
        border = "rounded",
      },
    },
    init = function()
      vim.api.nvim_create_user_command("Crates", function()
        require("crates").show_popup()
      end, { desc = "Show crate popup" })
    end,
  },
}
