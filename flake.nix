{
  description = "Neovim configuration with Nix-provided plugins";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          # All plugins provided by Nix (39 out of 40 total plugins)
          plugins = with pkgs.vimPlugins; [
            # Core dependencies
            lazy-nvim
            plenary-nvim
            nvim-web-devicons

            # LSP & Language Support
            nvim-lspconfig
            mason-nvim
            mason-lspconfig-nvim
            mason-tool-installer-nvim
            mason-nvim-dap-nvim
            fidget-nvim
            lazydev-nvim

            # Completion & Snippets
            blink-cmp
            friendly-snippets

            # Editor Features
            nvim-autopairs
            nvim-ts-autotag
            comment-nvim
            conform-nvim
            flash-nvim
            inc-rename-nvim
            refactoring-nvim
            vim-sleuth
            todo-comments-nvim
            trouble-nvim
            persistence-nvim

            # Debug Adapter Protocol
            nvim-dap
            nvim-dap-ui
            nvim-nio
            nvim-dap-go

            # Git Integration
            neogit
            diffview-nvim
            octo-nvim

            # UI & Interface
            lualine-nvim
            which-key-nvim
            snacks-nvim
            mini-nvim
            render-markdown-nvim
            markdown-preview-nvim

            # Optional dependencies
            noice-nvim
            telescope-nvim

            # AI Integration
            claudecode-nvim
          ];

          # Create plugin farm for lazy.nvim
          mkEntryFromDrv =
            drv:
            if nixpkgs.lib.isDerivation drv then
              {
                name = "${nixpkgs.lib.getName drv}";
                path = drv;
              }
            else
              drv;

          pluginFarm = pkgs.linkFarm "nvim-plugins" (builtins.map mkEntryFromDrv plugins);

          # Treesitter parsers
          treesitterParsers = pkgs.symlinkJoin {
            name = "treesitter-parsers";
            paths =
              (pkgs.vimPlugins.nvim-treesitter.withPlugins (
                p: with p; [
                  lua
                  nix
                  bash
                  c
                  css
                  diff
                  html
                  javascript
                  typescript
                  markdown
                  markdown_inline
                  vim
                  vimdoc
                  json
                  yaml
                  go
                  python
                  rust
                ]
              )).dependencies;
          };

          # Generate init.lua that sets up lazy.nvim with Nix plugins
          generatedInit =
            pkgs.writeText "init.lua" # lua
              ''
                -- Generated init.lua for Nix-provided plugins

                -- Load basic configuration (options, keymaps, etc.)
                require('config.options')

                -- Bootstrap lazy.nvim if not available via Nix
                local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
                if not (vim.uv or vim.loop).fs_stat(lazypath) then
                  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
                  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
                  if vim.v.shell_error ~= 0 then
                    vim.api.nvim_echo({
                      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
                      { out, 'WarningMsg' },
                      { '\nPress any key to exit...' },
                    }, true, {})
                    vim.fn.getchar()
                    os.exit(1)
                  end
                end
                vim.opt.rtp:prepend(lazypath)

                -- Configure lazy.nvim to use Nix-provided plugins
                local lazyOptions = {
                  lockfile = vim.fn.stdpath 'data' .. '/lazy-lock.json',
                  ui = {
                    icons = vim.g.have_nerd_font and {} or {
                      cmd = '⌘', config = '🛠', event = '📅', ft = '📂', init = '⚙',
                      keys = '🗝', plugin = '🔌', runtime = '💻', require = '🌙',
                      source = '📄', start = '🚀', task = '📌', lazy = '💤 ',
                    },
                  },
                  performance = {
                    reset_packpath = false,
                    rtp = { reset = false }
                  },
                  dev = {
                    -- Use plugins from Nix store first
                    path = "${pluginFarm}",
                    patterns = { "." },
                    -- Enable fallback for plugins not in nixpkgs
                    fallback = true,
                  },
                  install = {
                    -- Allow lazy.nvim to install missing plugins
                    missing = true,
                  },
                }

                -- Setup lazy.nvim with your plugins
                require('lazy').setup({
                  { import = 'plugins' },
                }, lazyOptions)
              '';

          neovim-config = pkgs.neovim.override {
            configure = {
              customRC = ''
                " Add config directory to runtime path
                set runtimepath^=${./.}

                " Load the generated init.lua
                luafile ${generatedInit}
              '';
              packages.all.start = plugins;
            };
          };

          # Create a wrapper that includes treesitter parsers
          neovim-wrapped = pkgs.writeShellScriptBin "nvim" ''
            export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
            mkdir -p "$XDG_CONFIG_HOME/nvim"

            # Link treesitter parsers if they don't exist
            if [ ! -d "$XDG_CONFIG_HOME/nvim/parser" ]; then
              ln -sf "${treesitterParsers}/parser" "$XDG_CONFIG_HOME/nvim/parser"
            fi

            exec ${neovim-config}/bin/nvim "$@"
          '';
        in
        {
          default = neovim-wrapped;
          neovim = neovim-wrapped;
          neovim-unwrapped = neovim-config;
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # The configured neovim
              self.packages.${system}.default

              # System tools
              git
              ripgrep
              fd
              unzip
              gcc

              # LSP servers
              lua-language-server
              nixd
              nil
              nodePackages.bash-language-server
              nodePackages.yaml-language-server
              rust-analyzer
              gopls
              pyright
              clang-tools
              taplo
              marksman
              vtsls

              # Formatters
              stylua
              prettierd

              # Debug tools
              delve
            ];

            shellHook = ''
              echo "🚀 Neovim with 39 Nix-provided plugins loaded!"
              echo "📦 Missing plugins (like multiple-cursors.nvim) will be installed by lazy.nvim on first run."
              echo "🔧 Use 'nvim' to start editing."
              echo ""
              echo "Available tools:"
              echo "  • All LSP servers and formatters included"
              echo "  • Treesitter parsers pre-installed"
              echo "  • Debug adapters ready (delve for Go)"
            '';
          };
        }
      );
    };
}
