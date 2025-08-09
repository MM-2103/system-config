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
vim.o.timeoutlen = 500

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
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>f', ":Pick files<CR>")
vim.keymap.set('n', '<leader>g', ":Pick grep_live<CR>")
vim.keymap.set('n', '<leader>fe', ':lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'H', ':bprevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'L', ':bnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', 'bd', ':bdelete<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Plugins --
vim.pack.add({
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
	{ src = "https://github.com/echasnovski/mini.nvim" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

require "mini.pick".setup()
require "mason".setup{
				ensure_installed = {
						"intelephense",
						"phpactor",
						"typescript-language-server",
						"pint",
				},
}
require "nvim-treesitter".setup {
	ensure_installed = { "php", "javascript", "lua" },
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
require('mini.files').setup {
	-- Customization of shown content
	content = {
		-- Predicate for which file system entries to show
		filter = nil,
		-- What prefix to show to the left of file system entry
		prefix = nil,
		-- In which order to show file system entries
		sort = nil,
	},

	-- Module mappings created only inside explorer.
	-- Use `''` (empty string) to not create one.
	mappings = {
		close = '<leader>fe',
		go_in = 'l',
		go_in_plus = 'L',
		go_out = 'h',
		go_out_plus = 'H',
		mark_goto = "'",
		mark_set = 'm',
		reset = '<BS>',
		reveal_cwd = '@',
		show_help = 'g?',
		synchronize = '=',
		trim_left = '<',
		trim_right = '>',
	},

	-- General options
	options = {
		-- Whether to delete permanently or move into module-specific trash
		permanent_delete = true,
		-- Whether to use for editing directories
		use_as_default_explorer = true,
	},

	-- Customization of explorer windows
	windows = {
		-- Maximum number of windows to show side by side
		max_number = math.huge,
		-- Whether to show preview of file/directory under cursor
		preview = false,
		-- Width of focused window
		width_focus = 50,
		-- Width of non-focused window
		width_nofocus = 15,
		-- Width of preview window
		width_preview = 25,
	},
}
require('mini.basics').setup()
require('mini.extra').setup()
require('mini.icons').setup()
require('mini.comment').setup()
require('mini.completion').setup()
require('mini.statusline').setup()
require('mini.tabline').setup()

-- Colorscheme --
vim.cmd("colorscheme gruvbox")

-- LSP --
vim.lsp.enable({ "lua_ls", "intelephense", "phpactor" })

-- Scripts --
vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
