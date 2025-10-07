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
vim.keymap.set('n', '<leader>sf', ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<leader>sg', ":Telescope grep_string<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>fe', ':Oil<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gf', ':Git<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { noremap = true, silent = true })
vim.keymap.set('n', 'bd', ':bdelete<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { noremap = true, silent = true })
vim.keymap.set('n', 'H', ':bprevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'L', ':bnext<CR>', { noremap = true, silent = true })
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
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

require "mason".setup()
require "nvim-treesitter".setup {
  ensure_installed = { "php", "javascript", "lua", "c", "nix", "html", "c_sharp", "go", "razor" },
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
require('mini.statusline').setup()
require('mini.tabline').setup()
require('mini.starter').setup()
require('mini.notify').setup()

require('oil').setup {
  view_options = {
    -- Show files and directories that start with "."
    show_hidden = true,
    -- This function defines what is considered a "hidden" file
    is_hidden_file = function(name, bufnr)
      local m = name:match("^%.")
      return m ~= nil
    end,
    -- This function defines what will never be shown, even when `show_hidden` is set
    is_always_hidden = function(name, bufnr)
      return false
    end,
    -- Sort file names with numbers in a more intuitive order for humans.
    -- Can be "fast", true, or false. "fast" will turn it off for large directories.
    natural_order = "fast",
    -- Sort file and directory names case insensitive
    case_insensitive = false,
    sort = {
      -- sort order can be "asc" or "desc"
      -- see :help oil-columns to see which columns are sortable
      { "type", "asc" },
      { "name", "asc" },
    },
    -- Customize the highlight group for the file name
    highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
      return nil
    end,
  },
}

require('telescope').setup()

require('mason-lspconfig').setup()

require('which-key').setup {
  preset = "helix",
}

require('blink.cmp').setup {
  -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
  -- 'super-tab' for mappings similar to vscode (tab to accept)
  -- 'enter' for enter to accept
  -- 'none' for no mappings
  --
  -- All presets have the following mappings:
  -- C-space: Open menu or open docs if already open
  -- C-n/C-p or Up/Down: Select next/previous item
  -- C-e: Hide menu
  -- C-k: Toggle signature help (if signature.enabled = true)
  --
  -- See :h blink-cmp-config-keymap for defining your own keymap
  keymap = { preset = 'default' },

  appearance = {
    -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
    nerd_font_variant = 'mono'
  },

  -- (Default) Only show the documentation popup when manually triggered
  completion = { documentation = { auto_show = true } },

  -- Default list of enabled providers defined so that you can extend it
  -- elsewhere in your config, without redefining it, due to `opts_extend`
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
  -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
  -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
  --
  -- See the fuzzy documentation for more information
  fuzzy = { implementation = "prefer_rust_with_warning" }
}

-- Colorscheme --
vim.cmd("colorscheme gruvbox")

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
    vim.lsp.buf.format()
  end,
})
