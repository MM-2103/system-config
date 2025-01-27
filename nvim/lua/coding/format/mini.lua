return {
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()
    require('mini.move').setup()
    require('mini.statusline').setup {
      content = {
        -- Content for active window
        active = nil,
        -- Content for inactive window(s)
        inactive = nil,
      },

      -- Whether to use icons by default
      use_icons = true,

      -- Whether to set Vim's settings for statusline (make it always shown)
      set_vim_settings = true,
    }
    require('mini.notify').setup()
    require('mini.icons').setup()
    require('mini.pairs').setup()
  end,
}
