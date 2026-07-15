return {
  {
    "mfussenegger/nvim-dap",
    ft = { "python", "rust" },
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      vim.fn.sign_define("DapBreakpoint", {
        text = "B",
        texthl = "DiagnosticSignError",
      })
      vim.fn.sign_define("DapStopped", {
        text = ">",
        texthl = "DiagnosticSignInfo",
        linehl = "Visual",
        numhl = "DiagnosticSignInfo",
      })

      local debugpy_python = vim.fs.joinpath(
        vim.fn.stdpath("data"),
        "mason",
        "packages",
        "debugpy",
        "venv",
        vim.fn.has("win32") == 1 and "Scripts" or "bin",
        vim.fn.has("win32") == 1 and "python.exe" or "python"
      )

      require("dap-python").setup(debugpy_python)
      require("dap-python").test_runner = "pytest"

      -- Rust 调试由 rustaceanvim 借助 codelldb 接管:打开 Rust 程序时
      -- 通过 :RustLsp debuggables 自动注册 DAP 配置。本文件只需在
      -- rust filetype 下加载 nvim-dap,rustaceanvim 检测到 dap 已就绪即可。
    end,
  },
}
