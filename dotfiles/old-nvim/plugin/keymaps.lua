-- =====================================================================
-- For Basic Keymaps See `:help vim.keymap.set()`
-- =====================================================================
-- Alias vim.keymap.set to set for easier to read syntax
local set = vim.keymap.set

-- =====================================================================
-- General Keymaps
-- =====================================================================
set('n', '<leader>fc', function()
  Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[F]ind [C]onfig Files' })

set('n', '<leader>pC', function()
  Snacks.picker.colorschemes()
end, { desc = '[P]review [C]olor schemes' })

set('n', '<leader>sh', function()
  Snacks.picker.help()
end, { desc = '[S]earch [H]elp' })

set('n', '<leader>sk', function()
  Snacks.picker.keymaps()
end, { desc = '[S]earch [K]eymaps' })

set('n', '<leader>sR', function()
  Snacks.picker.resume()
end, { desc = 'Resume' })

set('n', '<leader>su', function()
  Snacks.picker.undo()
end, { desc = '[S]earch [U]ndo History' })

set('n', '<leader>z', function()
  Snacks.zen()
end, { desc = 'Toggle [Z]en Mode' })

set('n', '<leader>lg', function()
  Snacks.lazygit()
end, { desc = '[L]azy[G]it' })

-- =====================================================================
-- Security Keymaps
-- =====================================================================
-- Toggle cloak for env files
set('n', '<leader>cc', '<cmd>:CloakToggle<cr>', { desc = 'Toggle Cloak for Env files' })
-- Toggle cloak for a current line
set('n', '<leader>cpl', '<cmd>:CloakPreviewLine<cr>', { desc = 'Toggle Cloak preview for current line' })

-- =====================================================================
-- Navigation Keymaps
-- =====================================================================
-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
-- TIP: Disable arrow keys in normal mode
set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Set highlight on search, but clear on pressing <Esc> in normal mode
set('n', '<Esc>', '<cmd>nohlsearch<CR>')
-- Open oil file picker
set('n', '<leader>-', require('oil').toggle_float, { desc = 'Open Oil' })
-- Easier exit terminal mode
set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
-- quit
set('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit All' })
-- save file
set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- =====================================================================
-- Formatting Keymaps
-- =====================================================================
-- better indenting
set('v', '<', '<gv')
set('v', '>', '>gv')

-- ---------------------------------------------------------------------
-- MiniFiles helpers
-- ---------------------------------------------------------------------
local MiniFiles = require 'mini.files'

-- =====================================================================
-- Explorer Keymaps
-- =====================================================================
set('n', '<leader>fe', ':lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', { noremap = true, silent = true })

-- =====================================================================
-- Search Keymaps
-- =====================================================================
set('n', '<leader>sf', function()
  Snacks.picker.files()
end, { desc = '[S]earch [F]iles' })

set('n', '<leader>ss', function()
  Snacks.picker.smart()
end, { desc = '[S]earch [S]mart Files' })

set('n', '<leader>sg', function()
  Snacks.picker.grep()
end, { desc = '[S]earch [G]rep' })

set('n', '<leader>/', function()
  Snacks.picker.grep()
end, { desc = 'Search using grep in current buffer ' })

set('n', '<leader>gr', '<cmd>:GrugFar<cr>', { desc = 'Search with Grug' })

-- =====================================================================
-- Git Keymaps
-- =====================================================================
set('n', '<leader>gs', function()
  Snacks.picker.git_status()
end, { desc = 'Search [G]it [S]atus' })

set('n', '<leader>fg', function()
  Snacks.picker.git_files()
end, { desc = '[F]ind [G]it Files' })

set('n', '<leader>gb', function()
  Snacks.picker.git_branches()
end, { desc = 'Search [G]it [B]ranches' })

set('n', '<leader>gl', function()
  Snacks.picker.git_log()
end, { desc = 'Search [G]it [L]og' })

set('n', '<leader>gf', function()
  Snacks.picker.git_log_file()
end, { desc = 'Search [G]it log for current [F]ile' })

set('n', '<leader>glb', function()
  require('gitsigns').toggle_current_line_blame()
end, { desc = 'Toggle [G]it [L]ine [B]lame' })

-- =====================================================================
-- LSP Keymap
-- =====================================================================
set('n', '<leader>gd', function()
  Snacks.picker.lsp_definitions()
end, { desc = '[G]oto [D]efinition' })

set('n', '<leader>gD', function()
  Snacks.picker.lsp_declarations()
end, { desc = '[G]oto [D]eclaration' })

set('n', '<leader>gr', function()
  Snacks.picker.lsp_references()
end, { desc = '[G]oto [R]eference' })

set('n', '<leader>gI', function()
  Snacks.picker.lsp_implementations()
end, { desc = '[G]oto [I]mplementation' })

set('n', '<leader>gt', function()
  Snacks.picker.lsp_type_definitions()
end, { desc = '[G]oto [T]ype Definitions' })

-- =====================================================================
-- Test Keymaps
-- =====================================================================
set('n', '<leader>tn', function()
  require('neotest').run.run()
end, { desc = 'Run Nearest' })

set('n', '<leader>tl', function()
  require('neotest').run.run_last()
end, { desc = 'Run Last' })

set('n', '<leader>ts', function()
  require('neotest').summary.toggle()
end, { desc = 'Toggle Summary' })

-- =====================================================================
-- Commands Keymaps
-- =====================================================================
set('n', '<leader>:', function()
  Snacks.picker.command_history()
end, { desc = 'Search Command History' })

set('n', '<leader>sa', function()
  Snacks.picker.autocmds()
end, { desc = '[S]earch [A]utocmds' })

set('n', '<leader>sc', function()
  Snacks.picker.commands()
end, { desc = '[S]earch [C]ommands' })

-- =====================================================================
-- Todo, Trouble
-- =====================================================================
set('n', '<leader>ct', function()
  Snacks.picker.todo_comments()
end, { desc = '[C]heck [T]odo' })

set('n', '<leader>dt', '<cmd>Trouble diagnostics toggle<cr>', { desc = '[D]iagnostics [T]rouble)' })

set('n', '<leader>td', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { silent = true, noremap = true })

-- =====================================================================
-- Diagnostics Keymaps
-- =====================================================================
set('n', '<leader>sd', function()
  Snacks.picker.diagnostics()
end, { desc = '[S]earch [D]iagnostics' })

set('n', '<leader>sD', function()
  Snacks.picker.diagnostics_buffer()
end, { desc = '[S]earch Buffer [D]iagnostics' })

-- set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
-- set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
-- set('n', '<leader>em', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
-- set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
--
-- set('n', '<leader>sr', function()
--   Snacks.picker.registers()
-- end, { desc = '[S]earch [R]egisters' })

-- =====================================================================
-- export
-- =====================================================================
set('n', '<leader>mp', function() -- Using <leader>mp for Markdown to PDF
  local current_file_path = vim.api.nvim_buf_get_name(0)

  if current_file_path == '' or not current_file_path:match '%.md$' then
    vim.notify('Cannot export: Current buffer is not a saved Markdown (.md) file.', vim.log.levels.WARN)
    return
  end

  local output_pdf_root_name = vim.fn.fnamemodify(current_file_path, ':r')
  local output_pdf_path = output_pdf_root_name .. '.pdf'

  local escaped_input_path = vim.fn.fnameescape(current_file_path)
  local escaped_output_path = vim.fn.fnameescape(output_pdf_path)

  local command_to_execute = 'mtp ' .. escaped_input_path .. ' ' .. escaped_output_path

  -- For debugging: use 'vertical terminal ' (shows output in a split window)
  -- vim.cmd('vertical terminal ' .. command_to_execute)
  vim.cmd('!' .. command_to_execute)

  vim.notify('Attempting to export ' .. current_file_path .. ' to ' .. output_pdf_path .. '...', vim.log.levels.INFO)
  vim.notify('Attempting to export ' .. current_file_path .. ' to ' .. output_pdf_path .. '...', vim.log.levels.INFO)
end, { desc = 'Export [M]arkdown to [P]DF' })
