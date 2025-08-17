local M = {}

function M.setup()
  --  This function gets run when an LSP attaches to a particular buffer.
  --    That is to say, every time a new file is opened that is associated with
  --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
  --    function will be executed to configure the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, opts)
        local options = vim.tbl_extend('force', { buffer = event.buf, desc = 'LSP: ' .. desc }, opts or {})
        vim.keymap.set('n', keys, func, options)
      end

      -- Jump to the definition of the word under your cursor.
      --  This is where a variable was first declared, or where a function is defined, etc.
      --  To jump back, press <C-t>.
      map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
      map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      map('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
      map('gt', vim.lsp.buf.type_definition, '[G]oto [T]ype Definition')
      map('gr', vim.lsp.buf.references, '[G]oto [R]eferences')

      -- Get documentation under cursor
      map('K', vim.lsp.buf.hover, 'Hover Documentation')

      -- Handle code actions, rename, and formatting
      map('<leader>cr', function()
        return ':IncRename ' .. vim.fn.expand '<cword>'
      end, '[C]ode [R]ename', { expr = true })
      map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
      map('<leader>cA', function()
        vim.lsp.buf.code_action {
          context = { only = { 'quickfix', 'source' } },
        }
      end, '[C]ode [A]ction Fix All')
      map('<leader>f', function()
        vim.lsp.buf.format { async = true }
      end, '[F]ormat Document')

      -- Document and workspace symbols
      map('<leader>ds', vim.lsp.buf.document_symbol, '[D]ocument [S]ymbols')
      map('<leader>ws', vim.lsp.buf.workspace_symbol, '[W]orkspace [S]ymbols')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.server_capabilities.documentHighlightProvider then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- The following autocommand is used to enable inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })
end

function M.load_servers()
  local servers = {}
  
  -- Use debug info to find the actual path of this file
  local current_file = debug.getinfo(1, 'S').source:sub(2)
  local servers_dir = vim.fn.fnamemodify(current_file, ':h') .. '/servers'
  local server_pattern = servers_dir .. '/*.lua'
  
  local server_files = vim.fn.glob(server_pattern, false, true)
  
  for _, file in ipairs(server_files) do
    local server_name = vim.fn.fnamemodify(file, ':t:r')
    local ok, server_config = pcall(require, 'plugins.lsp.servers.' .. server_name)
    if ok and type(server_config) == 'table' then
      servers[server_name] = server_config
    end
  end
  
  return servers
end

function M.setup_servers()
  local servers = M.load_servers()

  -- NOTE: Simplified setup - bypass nixCats for now
  local lspconfig = require('lspconfig')
  for server_name, cfg in pairs(servers) do
    lspconfig[server_name].setup(cfg)
  end
  
  -- NOTE: nixCats: if nix, use lspconfig instead of mason
  --[[
  if require('nixCatsUtils').isNixCats then
    print('Using nixCats setup')
    -- set up the servers to be loaded on the appropriate filetypes!
    local lspconfig = require('lspconfig')
    for server_name, cfg in pairs(servers) do
      print('Setting up server:', server_name)
      lspconfig[server_name].setup(cfg)
    end
  else
    -- NOTE: nixCats: and if no nix, use mason

    -- Ensure the servers and tools above are installed
    --  To check the current status of installed tools and/or manually install
    --  other tools, you can run
    --    :Mason
    --
    --  You can press `g?` for help in this menu.
    require('mason').setup()

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local lspconfig = require('lspconfig')
          lspconfig[server_name].setup(servers[server_name] or {})
        end,
      },
    }
  end
  --]]
end

return M
