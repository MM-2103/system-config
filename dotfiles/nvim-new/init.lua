-- Read at the very top so the starter footer can report startup time.
local START = vim.uv.hrtime()

-- ---------------------------------------------------------------------------
-- Options
--
-- mini.basics sets a pile of sensible defaults, but only for options that
-- haven't been touched manually. Anything it already covers is left out here.
-- See `:h MiniBasics.config.options` for the list.
-- ---------------------------------------------------------------------------
vim.o.number = true
vim.o.relativenumber = true
vim.o.confirm = true
vim.o.swapfile = false
vim.o.clipboard = 'unnamedplus'
vim.o.winborder = 'rounded'

vim.o.list = true
vim.o.listchars = 'tab:» ,trail:·,nbsp:␣'

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true

-- Leave 'timeout' on. Turning it off makes Nvim wait forever to disambiguate
-- any mapping that is a prefix of another, which silently breaks motions.
vim.o.timeoutlen = 500

-- ---------------------------------------------------------------------------
-- Globals
-- ---------------------------------------------------------------------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.markdown_recommended_style = 0

-- ---------------------------------------------------------------------------
-- Plugins
-- ---------------------------------------------------------------------------

vim.pack.add({
  { src = 'https://github.com/ellisonleao/gruvbox.nvim' },
  { src = 'https://github.com/echasnovski/mini.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  -- Pinned to the 1.x release line so blink downloads a prebuilt binary
  -- instead of needing cargo. Following `main` means compiling on every update.
  { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1.*') },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/OXY2DEV/markview.nvim' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/tpope/vim-fugitive' },
})

-- ---------------------------------------------------------------------------
-- mini.nvim
-- ---------------------------------------------------------------------------
require('mini.basics').setup()

require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

require('mini.statusline').setup()
require('mini.tabline').setup()

require('mini.notify').setup()
-- setup() alone only provides the API. This is what routes `vim.notify`
-- through it.
vim.notify = require('mini.notify').make_notify()

-- mini.pick's setup() installs itself as `vim.ui.select`.
require('mini.extra').setup()
require('mini.pick').setup()
-- Tracks path frecency, which is what backs the starter's "Visited" entry.
require('mini.visits').setup()

require('mini.diff').setup()
require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.ai').setup({
  custom_textobjects = {
    B = MiniExtra.gen_ai_spec.buffer(),
    D = MiniExtra.gen_ai_spec.diagnostic(),
    I = MiniExtra.gen_ai_spec.indent(),
    L = MiniExtra.gen_ai_spec.line(),
    N = MiniExtra.gen_ai_spec.number(),
  },
})

-- Set up last: the items drive `:Pick`, so it reads better after mini.pick.
local starter = require('mini.starter')
starter.setup({
  -- Long-bracket string, so the art must sit at column 0: everything between
  -- the brackets is taken literally, indentation included.
  header = [[
=================     ===============     ===============   ========  ========
\\ . . . . . . .\\   //. . . . . . .\\   //. . . . . . .\\  \\. . .\\// . . //
||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||
|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||
|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\ . . . . ||
||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||
|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||
||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||
||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||
||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||
||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||
||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||
||   .=='    _-'          '-__\._-'         '-_./__-'         `' |. /|  |   ||
||.=='    _-'                                                     `' |  /==.||
=='    _-'                         DOOM                              \/    `==
\   _-'                                                                `-_   /
`''                                                                      ``']],

  items = {
    { name = 'Files',     action = 'Pick files',       section = 'Search' },
    { name = 'Grep live', action = 'Pick grep_live',   section = 'Search' },
    { name = 'Visited',   action = 'Pick visit_paths', section = 'Search' },
    { name = 'Help tags', action = 'Pick help',        section = 'Search' },

    {
      name = 'Config',
      action = 'edit ' .. vim.fn.stdpath('config') .. '/init.lua',
      section = 'Actions',
    },
    {
      name = 'Update plugins',
      action = function() vim.pack.update() end,
      section = 'Actions',
    },
    { name = 'Quit', action = 'qall', section = 'Actions' },
  },

  footer = function()
    return ('%d plugins   %.0f ms'):format(#vim.pack.get(), (vim.uv.hrtime() - START) / 1e6)
  end,

  content_hooks = {
    starter.gen_hook.adding_bullet(),
    starter.gen_hook.indexing('all', { 'Actions' }),
    starter.gen_hook.aligning('center', 'center'),
  },
})

-- ---------------------------------------------------------------------------
-- Treesitter
--
-- The `main` branch only understands `install_dir` in setup(); parsers are
-- installed imperatively and highlighting is started by Nvim, not the plugin.
--
-- Parsers are pinned to a plugin revision, so run `:TSUpdate` yourself after
-- `<leader>pu` bumps nvim-treesitter. Do it from a fresh session on the
-- starter dashboard, never with a source file open: replacing a parser that a
-- live highlighter is using segfaults Nvim.
-- ---------------------------------------------------------------------------
require('nvim-treesitter').install({
  'c',
  'c_sharp',
  'go',
  'html',
  'javascript',
  'lua',
  'markdown',
  'markdown_inline',
  'nix',
  'php',
  'php_only',
  'python',
  'razor',
  'toml',
  'yaml',
})

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  desc = 'Start treesitter for any filetype with an installed parser',
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then return end

    -- Treesitter indenting is still experimental upstream, so only opt in
    -- where an indents query actually exists.
    if vim.treesitter.query.get(lang, 'indents') then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- ---------------------------------------------------------------------------
-- Editor plugins
-- ---------------------------------------------------------------------------
require('oil').setup({
  view_options = { show_hidden = true },
})

require('which-key').setup({ preset = 'helix' })

require('markview').setup()

require('blink.cmp').setup({
  -- 'default' (C-y to accept), 'super-tab', 'enter', or 'none'.
  -- C-space opens the menu, C-n/C-p select, C-e hides, C-k toggles signature.
  -- See `:h blink-cmp-config-keymap`.
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = true } },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
})

require('conform').setup({
  formatters_by_ft = {
    c = { 'clang-format' },
    cpp = { 'clang-format' },
    cs = { 'csharpier' },
    css = { 'prettier' },
    html = { 'prettier' },
    javascript = { 'prettier' },
    json = { 'prettier' },
    lua = { 'stylua' },
    markdown = { 'prettier' },
    nix = { 'nixfmt' },
    php = { 'php_cs_fixer' },
    -- Order matters: fix lint errors, sort imports, then format.
    python = { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' },
    yaml = { 'prettier' },
  },
  -- Falls back to the LSP for anything without a formatter above (Go, Razor,
  -- Twig), and skips buffers with neither.
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
})

-- ---------------------------------------------------------------------------
-- LSP
-- ---------------------------------------------------------------------------
require('mason').setup()

-- Single source of truth for servers: mason installs them, and
-- mason-lspconfig's `automatic_enable` calls `vim.lsp.enable()` for each.
-- Only add an explicit `vim.lsp.enable()` for servers installed outside mason.
require('mason-lspconfig').setup({
  ensure_installed = {
    'basedpyright',
    'clangd',
    'csharp_ls',
    'gopls',
    'html',
    'lua_ls',
    'nil_ls',
    'phpactor',
    -- Serves double duty: the language server and conform's formatter are the
    -- same binary.
    'ruff',
    'twiggy_language_server',
  },
})

-- `ensure_installed` above only understands LSP servers, so conform's
-- formatters are installed here by Mason package name. clang-format comes
-- from the system and gopls formats Go itself, so neither is listed.
do
  local tools = { 'stylua', 'nixfmt', 'prettier', 'php-cs-fixer', 'csharpier' }
  local registry = require('mason-registry')
  registry.refresh(vim.schedule_wrap(function()
    for _, name in ipairs(tools) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() then pkg:install() end
    end
  end))
end

-- Teach lua_ls about the Nvim runtime. Deliberately not pulling in all of
-- 'runtimepath' -- that is slow and misbehaves when editing this very config.
-- See https://github.com/neovim/nvim-lspconfig/issues/3189
vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath('config')
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        version = 'LuaJIT',
        path = { 'lua/?.lua', 'lua/?/init.lua' },
      },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME, '${3rd}/luv/library' },
      },
    })
  end,
  settings = { Lua = {} },
})

vim.lsp.config('basedpyright', {
  settings = {
    basedpyright = {
      analysis = {
        -- basedpyright defaults to "recommended", which is stricter than
        -- upstream pyright and buries you in warnings about untyped
        -- third-party code. Raise this once the language feels familiar.
        typeCheckingMode = 'standard',
      },
    },
  },
})

-- Runs alongside basedpyright on purpose: it contributes lint diagnostics and
-- their code actions, nothing else. Hover is the one capability they both
-- claim, so it is turned off here. Formatting goes through conform.
vim.lsp.config('ruff', {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
})

-- Nvim ships with virtual text and virtual lines both off.
vim.diagnostic.config({
  severity_sort = true,
  virtual_lines = { current_line = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  },
})

-- ---------------------------------------------------------------------------
-- Colorscheme
-- ---------------------------------------------------------------------------
vim.cmd.colorscheme('gruvbox')

-- ---------------------------------------------------------------------------
-- Keymaps
--
-- Nvim already maps grn (rename), gra (code action), grr (references),
-- gri (implementation), grt (type definition), gO (document symbol),
-- i_CTRL-S (signature help), and K (hover, on attach). Those aren't repeated.
-- ---------------------------------------------------------------------------
local map = function(lhs, rhs, desc, mode)
  vim.keymap.set(mode or 'n', lhs, rhs, { desc = desc, silent = true })
end

map('<leader>so', '<Cmd>update<CR><Cmd>source<CR>', 'Save and source config')
map('<leader>pu', function() vim.pack.update() end, 'Update plugins')

map('<leader>sf', function() MiniPick.builtin.files() end, 'Search files')
map('<leader>sg', function() MiniPick.builtin.grep_live() end, 'Search by grep')
map('<leader>sb', function() MiniPick.builtin.buffers() end, 'Search buffers')
map('<leader>sh', function() MiniPick.builtin.help() end, 'Search help')
map('<leader>sd', function() MiniExtra.pickers.diagnostic() end, 'Search diagnostics')
map('<leader>sr', function() MiniPick.builtin.resume() end, 'Resume last picker')

map('<leader>fe', '<Cmd>Oil<CR>', 'File explorer')
map('<leader>gf', '<Cmd>Git<CR>', 'Git status')

map('<leader>lf', function() require('conform').format({ async = true }) end, 'Format buffer')
map('<leader>ld', vim.diagnostic.open_float, 'Line diagnostics')
map('gd', vim.lsp.buf.definition, 'Goto definition')

-- Deliberately under <leader>: a bare `bd` would make `b` an ambiguous prefix
-- and stall the back-a-word motion until the next keypress.
map('<leader>bd', '<Cmd>bdelete<CR>', 'Delete buffer')
map('H', '<Cmd>bprevious<CR>', 'Previous buffer')
map('L', '<Cmd>bnext<CR>', 'Next buffer')

map('<Esc>', '<Cmd>nohlsearch<CR>', 'Clear search highlight')
map('<C-z>', '<Nop>', 'Disable suspend')
