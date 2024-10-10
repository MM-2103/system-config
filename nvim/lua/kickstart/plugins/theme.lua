return {
  'rose-pine/neovim',
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'rose-pine'
    vim.cmd.hi 'Comment gui=none'
  end,
}
-- vim: ts=2 sts=2 sw=2 et
