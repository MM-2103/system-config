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
vim.o.timeout = false
vim.o.ttimeout = true
vim.o.ttimeoutlen = 50

-- Global Variables --
vim.g.have_nerd_font = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.markdown_recommended_style = 0

-- Keybinds --
vim.keymap.set('n', '<leader>so', '<cmd>update<CR><cmd>source %<CR>',
  { remap = false, silent = true, desc = 'Save and source current file' })
vim.keymap.set('n', '<leader>sf', '<cmd>Pick files<CR>', { remap = false, silent = true, desc = 'Find files' })
vim.keymap.set('n', '<leader>sg', '<cmd>Pick grep<CR>', { remap = false, silent = true, desc = 'Grep string' })
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, { remap = false, silent = true, desc = 'Format buffer' })
vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, { remap = false, silent = true, desc = 'Diagnostics float' })
vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { remap = false, silent = true, desc = 'Rename symbol' })
vim.keymap.set('n', '<leader>fe', '<cmd>Oil<CR>', { remap = false, silent = true, desc = 'File explorer' })
vim.keymap.set('n', '<leader>gf', '<cmd>Git<CR>', { remap = false, silent = true, desc = 'Git status' })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { remap = false, silent = true, desc = 'Go to definition' })
vim.keymap.set('n', 'bd', '<cmd>bdelete<CR>', { remap = false, silent = true, desc = 'Delete buffer' })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { remap = false, silent = true, desc = 'Hover documentation' })
vim.keymap.set('n', 'H', '<cmd>bprevious<CR>', { remap = false, silent = true, desc = 'Previous buffer' })
vim.keymap.set('n', 'L', '<cmd>bnext<CR>', { remap = false, silent = true, desc = 'Next buffer' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { remap = false, silent = true, desc = 'Clear search highlights' })
vim.keymap.set('n', '<C-z>', '<Nop>', { silent = true, desc = 'Disable suspend' })

-- Plugins --
vim.pack.add({
  { src = "https://github.com/ellisonleao/gruvbox.nvim" },
  { src = "https://github.com/OXY2DEV/markview.nvim" },
  { src = "https://github.com/echasnovski/mini.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/saghen/blink.cmp",                name = "blink.cmp" },
  { src = "https://github.com/saghen/blink.lib",                name = "blink.lib" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

require "mason".setup()

require('nvim-treesitter').install { "php", "javascript", "lua", "c", "nix", "html", "go", "razor" }

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable treesitter highlighting',
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable treesitter indentation',
  callback = function()
    pcall(function()
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end)
  end,
})

require('mini.basics').setup()
require('mini.pick').setup()
require('mini.extra').setup()
require('mini.icons').setup()
require('mini.comment').setup()
require('mini.statusline').setup()
require('mini.tabline').setup()
require('mini.starter').setup()
require('mini.notify').setup()

require('oil').setup {
  view_options = {
    show_hidden = true,
    natural_order = "fast",
    case_insensitive = false,
    sort = {
      { "type", "asc" },
      { "name", "asc" },
    },
  },
}

require('which-key').setup {
  preset = "helix",
}

require('blink.cmp').setup {
  keymap = { preset = 'default' },
  appearance = {
    nerd_font_variant = 'mono'
  },
  completion = { documentation = { auto_show = true } },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  fuzzy = { implementation = "prefer_rust" }
}

-- Colorscheme --
vim.cmd.colorscheme("gruvbox")

-- LSP --
vim.lsp.enable({ "lua_ls", "intelephense", "phpactor", "clangd", "nil_ls", "html", "twiggy_language_server", "csharp_ls",
  "gopls" })

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
    vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
  end,
})

vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Build blink.cmp Rust fuzzy on install/update',
  pattern = 'blink.cmp',
  callback = function(ev)
    if ev.data.kind == 'install' or ev.data.kind == 'update' then
      local path = vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'pack', 'core', 'opt', 'blink.cmp')
      vim.system({ 'cargo', 'build', '--release' }, { cwd = path }):wait()
    end
  end,
})
