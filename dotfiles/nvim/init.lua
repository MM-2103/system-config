-- Editor Options --
vim.o.relativenumber = true
vim.o.confirm = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.list = true
vim.o.cursorline = true
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.signcolumn = 'yes'
vim.o.clipboard = 'unnamedplus'
vim.o.winborder = "rounded"
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.timeout = false  -- Disable timeout for mappings
vim.o.ttimeout = true  -- Keep timeout for key codes
vim.o.ttimeoutlen = 50 -- Short timeout for key codes (escape sequences)

-- Global Variables --
vim.g.have_nerd_font = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.markdown_recommended_style = 0
vim.g.base16_background_transparent = 1
vim.g.base16_colorspace = 256

-- Keybinds --
vim.keymap.set('n', '<leader>so', ':update<CR> :source<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, { noremap = true, silent = true })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { noremap = true, silent = true })
vim.keymap.set('n', 'gr', vim.lsp.buf.references, { noremap = true, silent = true })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, { noremap = true, silent = true })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { noremap = true, silent = true })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>sf', ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<leader>sg', ":Telescope grep_string<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<leader>fe', ':Oil<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'H', ':bprevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'L', ':bnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'bd', ':bdelete<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true })

-- Plugins --
vim.pack.add({
  { src = "https://github.com/ellisonleao/gruvbox.nvim" },
  { src = "https://github.com/echasnovski/mini.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

require "mason".setup()
require "nvim-treesitter".setup {
  ensure_installed = { "php", "javascript", "lua", "c", "nix", "html" },
  auto_install = true,
  highlight = {
    enable = true,
    -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
    --  If you are experiencing weird indenting issues, add the language to
    --  the list of additional_vim_regex_highlighting and disabled languages for indent.
    additional_vim_regex_highlighting = { 'ruby' },
  },
  indent = { enable = true, disable = { 'ruby' } },
}

require('mini.basics').setup()
require('mini.extra').setup()
require('mini.icons').setup()
require('mini.comment').setup()
require('mini.completion').setup()
require('mini.statusline').setup()
require('mini.tabline').setup()

require('oil').setup()

require('telescope').setup()

-- Colorscheme --
vim.cmd("colorscheme gruvbox")

-- LSP --
vim.lsp.enable({ "lua_ls", "intelephense", "phpactor", "clangd", "nil_ls", "html", "twiggy_language_server" })

-- Scripts --
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Format buffer before saving',
  group = vim.api.nvim_create_augroup('format-on-save', { clear = true }),
  callback = function()
    vim.lsp.buf.format()
  end,
})
