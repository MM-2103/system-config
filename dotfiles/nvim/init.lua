-- Editor Options --
vim.o.relativenumber = true
vim.o.confirm = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.list = true
vim.o.cursorline = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.signcolumn = 'yes'
vim.o.clipboard = 'unnamedplus'
vim.o.winborder = "rounded"
vim.o.tabstop = 4
vim.o.updatetime = 250
vim.o.timeoutlen = 10000

-- Global Variables --
vim.g.have_nerd_font = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.markdown_recommended_style = 0
vim.g.base16_background_transparent = 1
vim.g.base16_colorspace = 256

-- Keybinds --
vim.keymap.set('n', '<leader>so', ':update<CR> :source<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.keymap.set('n', '<leader>sf', ":Pick files<CR>")
vim.keymap.set('n', '<leader>o', ":Oil<CR>")

-- Plugins --
vim.pack.add({
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/stevearc/oil.nvim" },
})

require "mini.pick".setup()
require "oil".setup()

-- Colorscheme --
vim.cmd("colorscheme gruvbox")

-- LSP --
vim.lsp.enable({ "lua_ls", "intelephense" })

-- Scripts --
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('CursorHold', {
  desc = 'Auto-show diagnostics on hover',
  callback = function()
    local opts = {
      focusable = false,
      close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter', 'FocusLost' },
      border = 'rounded',
      source = 'always',
      prefix = ' ',
      scope = 'cursor',
    }
    vim.diagnostic.open_float(nil, opts)
  end,
})
