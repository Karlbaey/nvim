return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    lazy = false,
    config = function()
      require 'rainbow-delimiters.setup'.setup {
      strategy = {
          [''] = 'rainbow-delimiters.strategy.global',
      },
      query = {
        [''] = 'rainbow-delimiters',
      },
      highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
      },
    }

      -- Workaround: Neovim 0.12's parser:for_each_tree() no longer triggers
      -- parsing implicitly, so rainbow-delimiters' full_update callback never
      -- fires on initial attach.  Schedule a deferred re-apply so the parser
      -- has time to parse before we traverse it.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          vim.schedule(function()
            local lib = require("rainbow-delimiters.lib")
            local settings = lib.buffers[args.buf]
            if settings then
              settings.parser:parse()
              settings.strategy.on_reset(args.buf, settings)
            end
          end)
        end,
      })
    end,
  },
}