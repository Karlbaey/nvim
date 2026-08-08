if not vim.g.neovide then
  return
end

vim.o.guifont = "JetBrains Maple Mono:h18"

-- IME 按模式自动切换:Insert/Cmdline 启用,Normal 禁用
-- 避免 Normal 模式下移动光标时小狼毫等输入法触发 Windows 系统 beep
local function set_ime(event)
  if event:match("Enter$") then
    vim.g.neovide_input_ime = true
  else
    vim.g.neovide_input_ime = false
  end
end

local ime_group = vim.api.nvim_create_augroup("neovide_ime", { clear = true })

vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
  group = ime_group,
  pattern = "*",
  callback = function(args)
    set_ime(args.event)
  end,
})

vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
  group = ime_group,
  pattern = "[/\\?]",
  callback = function(args)
    set_ime(args.event)
  end,
})

vim.g.neovide_position_animation_length = 0.05
vim.g.neovide_scroll_animation_length = 0.08
vim.g.neovide_scroll_animation_far_lines = 1
vim.g.neovide_cursor_animation_length = 0.06
vim.g.neovide_cursor_short_animation_length = 0.03
vim.g.neovide_cursor_trail_size = 0.15
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_cursor_smooth_blink = false
vim.g.neovide_cursor_vfx_mode = ""
