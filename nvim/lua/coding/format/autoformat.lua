return { -- Autoformat
  'stevearc/conform.nvim',
  lazy = false,
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_fallback = true }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      return {
        timeout_ms = 3000,
        async = false, -- not recommended to change
        quiet = false, -- not recommended to change
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      sh = { 'shfmt' },
      php = { 'custom_pint' }, -- Use a custom formatter name instead of 'pint'
      blade = { 'blade-formatter', 'rustywind' },
      python = { 'black' },
      rust = { 'rustfmt' },
    },
    -- Define custom formatters
    formatters = {
      custom_pint = {
        command = 'pint',
        args = function()
          -- Default config path (e.g., in your home directory)
          local default_config = vim.fn.expand '/home/mm-2103/.config/pint/pint.json'
          -- Project-specific config path
          local project_config = vim.fn.getcwd() .. '/pint.json'

          -- Check if project_config exists
          if vim.fn.filereadable(project_config) == 1 then
            -- Use project-specific pint.json if it exists
            return { vim.fn.fnameescape(project_config) }
          else
            -- Fallback to default config
            return { '--config', vim.fn.fnameescape(default_config) }
          end
        end,
        -- Ensure pint processes the current buffer
        stdin = false,
      },
    },
  },
}
