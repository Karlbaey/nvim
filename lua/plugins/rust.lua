-- Rust 编辑体验的整合插件。rustaceanvim 接管 rust-analyzer 的启动、
-- 调试(codelldb)、cargo run/test 集成,并提供 RustLsp 命令族
-- (expandMacro / moveItem / joinLines 等)。因此 lsp.lua 里只注册
-- rust_analyzer 的 server 配置用于被 rustaceanvim 读取,但不 enable,
-- 避免两边重复启动同一个 LSP client。
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false,
    init = function()
      -- rustaceanvim 在 vim.lsp.enable 接管 rust-analyzer 之前读这套全局配置。
      vim.g.rustaceanvim = {
        -- 让 rust-analyzer 在保存/编辑时跑 clippy,实时 lint。
        -- 等价于 lsp 配置 settings["rust-analyzer"].check.command = "clippy"。
        server = {
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
              diagnostics = {
                -- experimental 里 setTest 不动
              },
            },
          },
        },
        -- 调试交给 codelldb(mason 安装),rustaceanvim 自动识别。
        -- 不在这里显式 setup,nvim-dap 在 dap.lua 里统一加载即可,
        -- rustaceanvim 会在打开 Rust 程序时提供 DAP 配置。
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
        -- 不在 lua/rust 源码里自动弹补全 crate 版本,避免干扰。
        -- Cargo.toml 里的版本高亮和补全总是开。
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
