return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1000,
  opts = {
    cmdline = { enabled = true },
    statuscolumn = { enabled = true },
    picker = {
      enabled = true,
      win = {
        input = {
          keys = {
            ['<c-h>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
            ['<c-i>'] = { 'toggle_ignored', mode = { 'i', 'n' } },
            ['<c-g>'] = { 'toggle_follow', mode = { 'i', 'n' } },
            ['<c-f>'] = { 'toggle_filter', mode = { 'i', 'n' } },
          },
        },
      },
    },
    explorer = { enabled = true },
    input = {
      enabled = true,
      -- Make snacks input the default for vim.ui.input
      override = true,
    },
    indent = {
      indent = {
        enabled = true,
        char = '‧', -- dotted line character
        only_current = true,
      },
      chunk = {
        enabled = true, -- enable chunk rendering with curved borders
        only_current = true,
        char = {
          corner_top = '╭', -- curved top corner
          corner_bottom = '╰', -- curved bottom corner
          horizontal = '', -- horizontal line
          vertical = '│', -- vertical line
          arrow = '', -- arrow for chunk indication
        },
      },
      scope = { enabled = true },
    },
    zen = { enabled = true },
    notify = {
      enabled = true,
      timeout = 3000,
      max_width = 60,
      max_height = 6,
      style = 'compact',
      top_down = true,
    },
    bigfile = {
      enabled = true,
      size = 1024 * 1024, -- 1MB
      setup = function(ctx)
        vim.b.minianimate_disable = true
        vim.schedule(function()
          vim.bo[ctx.buf].syntax = ctx.ft
        end)
      end,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesActionRename',
      callback = function(event)
        Snacks.rename.on_rename_file(event.data.from, event.data.to)
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
        Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
        Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
        Snacks.toggle.diagnostics():map '<leader>ud'
        Snacks.toggle.line_number():map '<leader>ul'
        Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
        Snacks.toggle.treesitter():map '<leader>uT'
        Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
        Snacks.toggle.inlay_hints():map '<leader>uh'
        Snacks.toggle.indent():map '<leader>ug'
        Snacks.toggle.zen():map '<leader>uz'
        Snacks.toggle.dim():map '<leader>uD'
      end,
    })
  end,
  keys = {
    -- Top Pickers & Explorer
    {
      '<leader><space>',
      function()
        Snacks.picker.smart()
      end,
      desc = 'Smart Find Files',
    },
    {
      '<leader>,',
      function()
        Snacks.picker.buffers()
      end,
      desc = 'Buffers',
    },
    {
      '<leader>/',
      function()
        Snacks.picker.grep()
      end,
      desc = 'Grep',
    },
    {
      '<leader>:',
      function()
        Snacks.picker.command_history()
      end,
      desc = 'Command History',
    },
    {
      '<leader>n',
      function()
        Snacks.picker.notifications()
      end,
      desc = 'Notification History',
    },
    {
      '<leader>e',
      function()
        Snacks.explorer()
      end,
      desc = 'File Explorer',
    },
    -- find
    {
      '<leader>fb',
      function()
        Snacks.picker.buffers()
      end,
      desc = 'Buffers',
    },
    {
      '<leader>fc',
      function()
        Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      end,
      desc = 'Find Config File',
    },
    {
      '<leader>ff',
      function()
        Snacks.picker.files()
      end,
      desc = 'Find Files',
    },
    {
      '<leader>fg',
      function()
        Snacks.picker.git_files()
      end,
      desc = 'Find Git Files',
    },
    {
      '<leader>fp',
      function()
        Snacks.picker.projects()
      end,
      desc = 'Projects',
    },
    {
      '<leader>fr',
      function()
        Snacks.picker.recent()
      end,
      desc = 'Recent',
    },
    -- git
    {
      '<leader>gb',
      function()
        Snacks.picker.git_branches()
      end,
      desc = 'Git Branches',
    },
    {
      '<leader>gl',
      function()
        Snacks.picker.git_log()
      end,
      desc = 'Git Log',
    },
    {
      '<leader>gL',
      function()
        Snacks.picker.git_log_line()
      end,
      desc = 'Git Log Line',
    },
    {
      '<leader>gs',
      function()
        Snacks.picker.git_status()
      end,
      desc = 'Git Status',
    },
    {
      '<leader>gS',
      function()
        Snacks.picker.git_stash()
      end,
      desc = 'Git Stash',
    },
    {
      '<leader>gd',
      function()
        Snacks.picker.git_diff()
      end,
      desc = 'Git Diff (Hunks)',
    },
    {
      '<leader>gf',
      function()
        Snacks.picker.git_log_file()
      end,
      desc = 'Git Log File',
    },
    -- Grep
    {
      '<leader>sb',
      function()
        Snacks.picker.lines()
      end,
      desc = 'Buffer Lines',
    },
    {
      '<leader>sB',
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = 'Grep Open Buffers',
    },
    {
      '<leader>sg',
      function()
        Snacks.picker.grep()
      end,
      desc = 'Grep',
    },
    {
      '<leader>sw',
      function()
        Snacks.picker.grep_word()
      end,
      desc = 'Visual selection or word',
      mode = { 'n', 'x' },
    },
    -- search
    {
      '<leader>s"',
      function()
        Snacks.picker.registers()
      end,
      desc = 'Registers',
    },
    {
      '<leader>s/',
      function()
        Snacks.picker.search_history()
      end,
      desc = 'Search History',
    },
    {
      '<leader>sa',
      function()
        Snacks.picker.autocmds()
      end,
      desc = 'Autocmds',
    },
    {
      '<leader>sb',
      function()
        Snacks.picker.lines()
      end,
      desc = 'Buffer Lines',
    },
    {
      '<leader>sc',
      function()
        Snacks.picker.command_history()
      end,
      desc = 'Command History',
    },
    {
      '<leader>sC',
      function()
        Snacks.picker.commands()
      end,
      desc = 'Commands',
    },
    {
      '<leader>sd',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = 'Diagnostics',
    },
    {
      '<leader>sD',
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = 'Buffer Diagnostics',
    },
    {
      '<leader>sh',
      function()
        Snacks.picker.help()
      end,
      desc = 'Help Pages',
    },
    {
      '<leader>sH',
      function()
        Snacks.picker.highlights()
      end,
      desc = 'Highlights',
    },
    {
      '<leader>si',
      function()
        Snacks.picker.icons()
      end,
      desc = 'Icons',
    },
    {
      '<leader>sj',
      function()
        Snacks.picker.jumps()
      end,
      desc = 'Jumps',
    },
    {
      '<leader>sk',
      function()
        Snacks.picker.keymaps()
      end,
      desc = 'Keymaps',
    },
    {
      '<leader>sl',
      function()
        Snacks.picker.loclist()
      end,
      desc = 'Location List',
    },
    {
      '<leader>sm',
      function()
        Snacks.picker.marks()
      end,
      desc = 'Marks',
    },
    {
      '<leader>sM',
      function()
        Snacks.picker.man()
      end,
      desc = 'Man Pages',
    },
    {
      '<leader>sp',
      function()
        Snacks.picker.lazy()
      end,
      desc = 'Search for Plugin Spec',
    },

    {
      '<leader>sq',
      function()
        Snacks.picker.qflist()
      end,
      desc = 'Quickfix List',
    },
    {
      '<leader>sR',
      function()
        Snacks.picker.resume()
      end,
      desc = 'Resume',
    },
    {
      '<leader>su',
      function()
        Snacks.picker.undo()
      end,
      desc = 'Undo History',
    },
    {
      '<leader>uC',
      function()
        Snacks.picker.colorschemes()
      end,
      desc = 'Colorschemes',
    },
    -- LSP
    {
      'gd',
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = 'Goto Definition',
    },
    {
      'gD',
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = 'Goto Declaration',
    },
    {
      'gr',
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = 'References',
    },
    {
      'gI',
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = 'Goto Implementation',
    },
    {
      'gy',
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = 'Goto T[y]pe Definition',
    },
    {
      '<leader>ss',
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = 'LSP Symbols',
    },
    {
      '<leader>sS',
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = 'LSP Workspace Symbols',
    },
    {
      '<leader>so',
      function()
        -- Get current buffer symbols from aerial using the correct API
        local aerial_ok, aerial = pcall(require, 'aerial')
        if not aerial_ok then
          vim.notify('Aerial not available', vim.log.levels.WARN)
          return
        end

        local bufnr = vim.api.nvim_get_current_buf()

        -- Use aerial's data module to get symbols
        local data_ok, data = pcall(require, 'aerial.data')
        if not data_ok then
          vim.notify('Aerial data module not available', vim.log.levels.WARN)
          return
        end

        local symbols = data.get_symbols(bufnr)

        if not symbols or #symbols == 0 then
          vim.notify('No aerial symbols found', vim.log.levels.WARN)
          return
        end

        -- Convert aerial symbols to snacks picker format
        local items = {}
        local function process_symbols(syms, level)
          level = level or 0
          for _, symbol in ipairs(syms) do
            local indent = string.rep('  ', level)
            local icon = ''
            if symbol.kind then
              -- Map common symbol kinds to icons
              local icons = {
                Class = '󰠱',
                Method = '󰊕',
                Function = '󰊕',
                Property = '󰜢',
                Variable = '󰀫',
                Interface = '󰜰',
                Module = '󰏗',
                Constructor = '󰛦',
                Enum = '󰕘',
                String = '󰀬',
                Object = '󰅩',
              }
              icon = icons[symbol.kind] or '󰈙'
            end

            table.insert(items, {
              text = indent .. icon .. ' ' .. symbol.name,
              lnum = symbol.lnum,
              col = symbol.col or 1,
              symbol = symbol,
            })

            -- Process children recursively
            if symbol.children then
              process_symbols(symbol.children, level + 1)
            end
          end
        end

        process_symbols(symbols)

        -- Use snacks picker to display symbols
        Snacks.picker.pick({
          source = {
            name = 'Aerial Symbols',
            items = items,
          },
          preview = {
            enabled = true,
          },
          prompt = 'Symbol: ',
        }, function(item)
          if item and item.lnum then
            vim.api.nvim_win_set_cursor(0, { item.lnum, (item.col or 1) - 1 })
            vim.cmd 'normal! zz'
          end
        end)
      end,
      desc = 'Outline/Symbols (Aerial)',
    },
  },
}
