return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    {
      'williamboman/mason.nvim',
      -- NOTE: nixCats: use lazyAdd to only enable mason if nix wasnt involved.
      -- because we will be using nix to download things instead.
      enabled = require('nixCatsUtils').lazyAdd(true, false),
      config = true,
    }, -- NOTE: Must be loaded before dependants
    {
      'williamboman/mason-lspconfig.nvim',
      -- NOTE: nixCats: use lazyAdd to only enable mason if nix wasnt involved.
      -- because we will be using nix to download things instead.
      enabled = require('nixCatsUtils').lazyAdd(true, false),
    },
    {
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      -- NOTE: nixCats: use lazyAdd to only enable mason if nix wasnt involved.
      -- because we will be using nix to download things instead.
      enabled = require('nixCatsUtils').lazyAdd(true, false),
    },

    -- Useful status updates for LSP.
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },

    -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          -- adds type hints for nixCats global
          { path = (nixCats.nixCatsPath or '') .. '/lua', words = { 'nixCats' } },
        },
      },
    },
    -- kickstart.nvim was still on neodev. lazydev is the new version of neodev
  },
  config = function()
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

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

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    -- local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
    -- vim.lsp.config('*', { capabilities = capabilities })

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    -- NOTE: nixCats: there is help in nixCats for lsps at `:h nixCats.LSPs` and also `:h nixCats.luaUtils`
    local servers = {}
    -- servers.clangd = {},
    -- servers.gopls = {},
    -- servers.pyright = {},
    -- servers.rust_analyzer = {},
    -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`tsserver`) will work just fine
    -- servers.tsserver = {},
    --

    -- NOTE: nixCats: nixd is not available on mason.
    -- Feel free to check the nixd docs for more configuration options:
    -- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
    if require('nixCatsUtils').isNixCats then
      servers.nixd = {
        settings = {
          nixd = {
            nixpkgs = {
              -- in the extras set of your package definition:
              -- nixdExtras.nixpkgs = ''import ${pkgs.path} {}''
              expr = nixCats.extra 'nixdExtras.nixpkgs' or [[import <nixpkgs> {}]],
            },
            options = {
              -- If you integrated with your system flake,
              -- you should use inputs.self as the path to your system flake
              -- that way it will ALWAYS work, regardless
              -- of where your config actually was.
              nixos = {
                -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
                expr = nixCats.extra 'nixdExtras.nixos_options',
              },
              -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
              -- You can override the correct one into your package definition on import in your main configuration,
              -- or just put an absolute path to where it usually is and accept the impurity.
              ['home-manager'] = {
                -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
                expr = nixCats.extra 'nixdExtras.home_manager_options',
              },
            },
            formatting = {
              command = { 'nixfmt' },
            },
            diagnostic = {
              suppress = {
                'sema-escaping-with',
              },
            },
          },
        },
      }
    else
      servers.rnix = {}
      servers.nil_ls = {}
    end
    servers.lua_ls = {
      -- cmd = {...},
      -- filetypes = { ...},
      -- capabilities = {},
      settings = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
          diagnostics = {
            globals = { 'nixCats' },
            disable = { 'missing-fields' },
          },
        },
      },
    }

    servers.vtsls = {
      typescript = {
        tsserver = {
          maxTsServerMemory = 8192,
        },
        preferences = {
          includePackageJsonAutoImports = 'off',
          importModuleSpecifier = 'project-relative',
          importModuleSpecifierEnding = 'js',
        },
      },
      javascript = {
        tsserver = {
          maxTsServerMemory = 8192,
        },
        preferences = {
          includePackageJsonAutoImports = 'off',
          importModuleSpecifier = 'project-relative',
          importModuleSpecifierEnding = 'js',
        },
      },
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
          entriesLimit = 50,
        },
      },
    }

    servers.marksman = {}

    -- NOTE: nixCats: if nix, use lspconfig instead of mason
    -- You could MAKE it work, using lspsAndRuntimeDeps and sharedLibraries in nixCats
    -- but don't... its not worth it. Just add the lsp to lspsAndRuntimeDeps.
    if require('nixCatsUtils').isNixCats then
      -- set up the servers to be loaded on the appropriate filetypes!
      for server_name, cfg in pairs(servers) do
        vim.lsp.config(server_name, cfg)
        vim.lsp.enable(server_name)
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
            vim.lsp.config(server_name, servers[server_name] or {})
            vim.lsp.enable(server_name)
          end,
        },
      }
    end
  end,
}

