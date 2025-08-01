return {
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    
    opts = {
      dir = vim.fn.stdpath 'state' .. '/sessions/',
      need = 1,
      branch = true,
    },
    
    config = function(_, opts)
      require('persistence').setup(opts)
      
      -- Configure session options to exclude certain filetypes
      vim.opt.sessionoptions:append('globals')
      vim.opt.sessionoptions:remove('blank')
      
      -- Set up autocmds for plugin integration hooks
      local group = vim.api.nvim_create_augroup('PersistenceHooks', { clear = true })
      
      -- Pre-save hook: close file trees and disable plugins
      vim.api.nvim_create_autocmd('User', {
        pattern = 'PersistenceSavePre',
        group = group,
        callback = function()
          -- Close nvim-tree if open
          if package.loaded['nvim-tree'] then
            require('nvim-tree.api').tree.close()
          end
          
          -- Close neo-tree if open
          if package.loaded['neo-tree'] then
            vim.cmd 'Neotree close'
          end
          
          -- Close snacks explorer if open
          if package.loaded['snacks'] then
            local snacks = require('snacks')
            if snacks.explorer then
              -- Close all explorer windows
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[buf].filetype
                if ft == 'snacks_explorer' then
                  vim.api.nvim_win_close(win, false)
                end
              end
            end
            
            -- Disable snacks indent before saving
            if snacks.indent then
              snacks.indent.disable()
            end
          end
        end,
      })
      
      -- Post-restore hook: re-enable and refresh plugins
      vim.api.nvim_create_autocmd('User', {
        pattern = 'PersistenceLoadPost',
        group = group,
        callback = function()
          vim.schedule(function()
            -- Close any lingering explorer windows that might have been restored
            if package.loaded['snacks'] then
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[buf].filetype
                if ft == 'snacks_explorer' then
                  vim.api.nvim_win_close(win, false)
                end
              end
              
              -- Re-enable snacks indent after restoring
              if require('snacks').indent then
                require('snacks').indent.enable()
              end
            end
            
            -- Refresh lualine if available
            if package.loaded['lualine'] then
              require('lualine').refresh()
            end
            
            -- Ensure we have at least one normal window
            local normal_wins = 0
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[buf].filetype
              if ft == '' or ft == 'lua' or ft == 'python' or ft == 'javascript' or ft == 'typescript' or ft == 'nix' then
                normal_wins = normal_wins + 1
              end
            end
            
            -- If no normal windows, create a new buffer
            if normal_wins == 0 then
              vim.cmd 'enew'
            end
          end)
        end,
      })
    end,
    
    keys = {
      {
        '<leader>qq',
        function()
          -- Check for unsaved buffers
          local unsaved_buffers = {}
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= '' then
                table.insert(unsaved_buffers, vim.fn.fnamemodify(name, ':t'))
              end
            end
          end

          if #unsaved_buffers > 0 then
            local files = table.concat(unsaved_buffers, ', ')
            local choice = vim.fn.confirm(
              'Unsaved changes in: ' .. files .. '\nSave all files?',
              '&Yes\n&No\n&Cancel',
              1
            )
            if choice == 1 then
              vim.cmd 'wa'
            elseif choice == 3 then
              return
            end
          end

          -- Save session and quit (persistence saves automatically on exit)
          vim.cmd 'qa!'
        end,
        desc = 'Save session and quit',
      },
      {
        '<leader>qs',
        function()
          require('persistence').load()
        end,
        desc = 'Restore session',
      },
      {
        '<leader>ql',
        function()
          require('persistence').select()
        end,
        desc = 'Search sessions',
      },
      {
        '<leader>qd',
        function()
          require('persistence').stop()
        end,
        desc = 'Stop session saving',
      },
    },
  },
}
