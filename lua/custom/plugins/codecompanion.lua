return {
  'olimorris/codecompanion.nvim',
  opts = {
    history = {
      enabled = true,
      -- How many conversations to save
      max_entries = 50,
      -- Where to store the history
      -- Make sure this directory exists
      storage_path = vim.fn.stdpath 'data' .. '/codecompanion/history',
    },
    strategies = {
      display = {
        diff = {
          enabled = true,
          close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
          layout = 'vertical', -- vertical|horizontal split for default provider
          opts = { 'internal', 'filler', 'closeoff', 'algorithm:patience', 'followwrap', 'linematch:120' },
          provider = 'mini_diff', -- default|mini_diff
        },
      },
      chat = {
        tools = {
          opts = {
            auto_submit_errors = false, -- Send any errors to the LLM automatically?
            auto_submit_success = false, -- Send any successful output to the LLM automatically?
          },
        },
        slash_commands = {
          ['buffer'] = {
            callback = 'strategies.chat.slash_commands.buffer',
            description = 'Insert a buffer',
            opts = {
              provider = 'snacks',
            },
          },
          ['file'] = {
            callback = 'strategies.chat.slash_commands.file',
            description = 'Insert a file',
            opts = {
              contains_code = true,
              max_lines = 1000,
              provider = 'snacks',
            },
          },
          ['help'] = {
            callback = 'strategies.chat.slash_commands.help',
            description = 'Insert help documentation',
            opts = {
              provider = 'snacks',
            },
          },
          ['symbols'] = {
            callback = 'strategies.chat.slash_commands.symbols',
            description = 'Insert symbols',
            opts = {
              provider = 'snacks',
              contains_code = true,
              filetype = true, -- Ensure filetype is recognized for symbols
              backends = { 'treesitter', 'lsp' }, -- Use both backends
              show_line_numbers = true,
            },
          },
        },
      },
    },
  },
  keys = {
    { '<leader>ap', mode = { 'n', 'x', 'o' }, '<cmd>CodeCompanion<cr>', desc = 'CodeCompanion prompt' },
    { '<leader>ac', mode = { 'n', 'x', 'o' }, '<cmd>CodeCompanionChat<cr>', desc = 'CodeCompanion chat' },
    { '<leader>aa', mode = { 'n', 'x', 'o' }, '<cmd>CodeCompanionActions<cr>', desc = 'CodeCompanion actions' },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'folke/snacks.nvim',
    'stevearc/aerial.nvim',
    {
      'echasnovski/mini.diff',
      config = function()
        local diff = require 'mini.diff'
        diff.setup {
          -- Disabled by default
          source = diff.gen_source.none(),
        }
      end,
    },
  },
}
