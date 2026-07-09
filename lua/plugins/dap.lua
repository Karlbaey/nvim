return {
  {
    "mfussenegger/nvim-dap",
    ft = "python",
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
    end,
  },
}
