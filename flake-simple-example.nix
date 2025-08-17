{
  description = "Simple Neovim configuration with Nix-provided plugins";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
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
      # Standalone packages for use without home-manager
      packages = forEachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          
          # All your plugins provided by Nix
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

            # Treesitter
            nvim-treesitter

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
            nordic-nvim
            mini-nvim
            render-markdown-nvim
            markdown-preview-nvim

            # Optional dependencies
            noice-nvim
            telescope-nvim

            # AI Integration
            claudecode-nvim
          ];

          # Create the plugin farm
          mkEntryFromDrv = drv:
            if nixpkgs.lib.isDerivation drv then {
              name = "${nixpkgs.lib.getName drv}";
              path = drv;
            } else drv;
          
          pluginFarm = pkgs.linkFarm "nvim-plugins" (builtins.map mkEntryFromDrv plugins);

          # Treesitter parsers
          treesitterParsers = pkgs.symlinkJoin {
            name = "treesitter-parsers";
            paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (
              p: with p; [
                lua nix bash c css diff html javascript typescript
                markdown markdown_inline vim vimdoc json yaml go python rust
              ]
            )).dependencies;
          };

          neovim-config = pkgs.neovim.override {
            configure = {
              customRC = ''
                lua << EOF
                -- Set up lazy.nvim to use Nix-provided plugins
                require("lazy").setup({
                  defaults = { lazy = true },
                  performance = {
                    reset_packpath = false,
                    rtp = { reset = false }
                  },
                  dev = {
                    path = "${pluginFarm}",
                    patterns = { "." },
                    fallback = true,
                  },
                  install = { missing = true },
                  spec = { { import = "plugins" } },
                })

                -- Add config to runtime path
                vim.opt.rtp:prepend("${./.}")
                
                -- Load main config
                require('init')
                EOF
              '';
              packages.all.start = plugins;
            };
          };
        in
        {
          default = neovim-config;
          neovim = neovim-config;
        }
      );

      # Development shells
      devShells = forEachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # The configured neovim
              self.packages.${system}.default

              # System tools
              git ripgrep fd unzip gcc

              # LSP servers
              lua-language-server nixd nil
              nodePackages.bash-language-server
              nodePackages.yaml-language-server
              rust-analyzer gopls pyright clang-tools
              taplo marksman vtsls

              # Formatters
              stylua prettierd

              # Debug tools
              delve
            ];

            shellHook = ''
              echo "Neovim with Nix-provided plugins loaded!"
              echo "Missing plugins will be installed by lazy.nvim on first run."
            '';
          };
        }
      );

      # Home Manager module (if you use home-manager)
      homeManagerModules.default = { lib, pkgs, ... }: {
        programs.neovim = {
          enable = true;
          viAlias = true;
          vimAlias = true;
          withNodeJs = true;
          defaultEditor = true;

          extraPackages = with pkgs; [
            # System tools
            gcc git ripgrep fd unzip

            # LSP servers  
            lua-language-server nixd nil
            nodePackages.bash-language-server
            nodePackages.yaml-language-server
            rust-analyzer gopls pyright clang-tools
            taplo marksman vtsls

            # Formatters
            stylua prettierd

            # Debug tools
            delve
          ];

          plugins = with pkgs.vimPlugins; [ lazy-nvim ];

          extraLuaConfig = 
            let
              plugins = with pkgs.vimPlugins; [
                # Your full plugin list here...
                plenary-nvim nvim-web-devicons nvim-lspconfig
                mason-nvim mason-lspconfig-nvim mason-tool-installer-nvim
                # ... (include all 39 plugins from our list)
              ];
              
              pluginFarm = pkgs.linkFarm "nvim-plugins" 
                (builtins.map (drv: {
                  name = "${lib.getName drv}";
                  path = drv;
                }) plugins);
            in
            ''
              require("lazy").setup({
                defaults = { lazy = true },
                performance = {
                  reset_packpath = false,
                  rtp = { reset = false }
                },
                dev = {
                  path = "${pluginFarm}",
                  patterns = { "." },
                  fallback = true,
                },
                install = { missing = true },
                spec = { { import = "plugins" } },
              })

              vim.opt.rtp:prepend("${./.}")
              require('init')
            '';
        };

        # Treesitter parsers
        xdg.configFile."nvim/parser".source = "${pkgs.vimPlugins.nvim-treesitter.withPlugins (p: with p; [
          lua nix bash c css diff html javascript typescript
          markdown markdown_inline vim vimdoc json yaml go python rust
        ])}/parser";
      };
    };
}