{ lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      # Core tools
      gcc
      libgcc
      git
      ripgrep
      fd
      unzip

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
      delve  # Go debugger
    ];

    plugins = with pkgs.vimPlugins; [ lazy-nvim ];

    extraLuaConfig =
      let
        plugins = with pkgs.vimPlugins; [
          # Core dependencies
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

        # Create symlink farm for lazy.nvim to find plugins
        mkEntryFromDrv =
          drv:
          if lib.isDerivation drv then
            {
              name = "${lib.getName drv}";
              path = drv;
            }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
        -- Set up lazy.nvim to use Nix-provided plugins
        require("lazy").setup({
          defaults = {
            lazy = true,
          },
          performance = {
            reset_packpath = false,
            rtp = {
              reset = false,
            }
          },
          dev = {
            -- Use plugins from Nix store
            path = "${lazyPath}",
            patterns = { "." },
            -- Enable fallback for plugins not in nixpkgs
            fallback = true,
          },
          install = {
            -- Allow lazy.nvim to install missing plugins (like multiple-cursors.nvim)
            missing = true,
          },
          spec = {
            -- Import your plugin configurations
            { import = "plugins" },
          },
        })

        -- Set up runtime path to find your config
        vim.opt.rtp:prepend("${./.}")
        
        -- Load your init configuration
        require('init')
      '';
  };

  # Provide treesitter parsers
  xdg.configFile."nvim/parser".source =
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths =
          (pkgs.vimPlugins.nvim-treesitter.withPlugins (
            plugins: with plugins; [
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
    in
    "${parsers}/parser";

  # Link your existing config
  xdg.configFile."nvim/lua" = {
    source = ./lua;
    recursive = true;
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
}