local M = {}

function M.setup()
  -- Configure LSP hover appearance (K key) - not handled by blink.cmp
  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = 'rounded',
    max_width = 80,
    max_height = 20,
  })

  -- Configure diagnostic appearance (not handled by blink)
  vim.diagnostic.config({
    float = {
      border = 'rounded',
      max_width = 80,
      header = '',
      prefix = '',
    },
    virtual_text = {
      prefix = '●',
    },
    signs = true,
    underline = true,
    update_in_insert = false,
  })

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

-- Helper function to check if an LSP binary is available in PATH
local function is_lsp_available(lsp_name)
  local handle = io.popen('which ' .. lsp_name .. ' 2>/dev/null')
  if handle then
    local result = handle:read('*a')
    handle:close()
    return result and result ~= ''
  end
  return false
end

-- Map server names to their binary names
local server_to_binary = {
  lua_ls = 'lua-language-server',
  nixd = 'nixd',
  nil_ls = 'nil',
  bashls = 'bash-language-server',
  vtsls = 'vtsls',
  yamlls = 'yaml-language-server',
  dockerls = 'docker-langserver',
  rust_analyzer = 'rust-analyzer',
  gopls = 'gopls',
  pyright = 'pyright',
  clangd = 'clangd',
  taplo = 'taplo',
  marksman = 'marksman',
  stylelint_lsp = 'stylelint-lsp',
  rnix = 'rnix-lsp',
}

function M.setup_servers()
  local servers = M.load_servers()
  local lspconfig = require('lspconfig')
  
  -- Categorize servers: available in PATH vs need Mason
  local nix_servers = {}
  local mason_servers = {}
  
  for server_name, cfg in pairs(servers) do
    local binary_name = server_to_binary[server_name] or server_name
    if is_lsp_available(binary_name) then
      nix_servers[server_name] = cfg
    else
      mason_servers[server_name] = cfg
    end
  end
  
  -- Setup servers available from Nix/PATH
  for server_name, cfg in pairs(nix_servers) do
    lspconfig[server_name].setup(cfg)
  end
  
  -- Setup Mason for missing servers
  if next(mason_servers) then
    require('mason').setup()
    
    local ensure_installed = vim.tbl_keys(mason_servers)
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    
    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          if mason_servers[server_name] then
            lspconfig[server_name].setup(mason_servers[server_name])
          end
        end,
      },
    }
  end
end

return M
