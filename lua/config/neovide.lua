if not vim.g.neovide then
  return
end

vim.o.guifont = "JetBrainsMono NFM:h12"

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
