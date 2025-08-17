{
  description = "Neovim configuration with nixCats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nixCats, ... }@inputs: let
    luaPath = "${./.}";
    forEachSystem = nixpkgs.lib.genAttrs nixCats.utils.supportedSystems;
    
    # Plugin categories - nixCats will provide these via Nix
    categoryDefinitions = { pkgs, settings, categories, name, ... }: {
      # LSP and core functionality
      lspPackages = with pkgs.vimPlugins; [
        nvim-lspconfig
        mason-nvim
        mason-lspconfig-nvim
        mason-tool-installer-nvim
        fidget-nvim
        lazydev-nvim
      ];
      
      # Completion and snippets
      completionPackages = with pkgs.vimPlugins; [
        blink-cmp
        friendly-snippets
      ];
      
      # UI and interface
      uiPackages = with pkgs.vimPlugins; [
        lualine-nvim
        nvim-web-devicons
        which-key-nvim
        snacks-nvim
        nordic-nvim
        mini-nvim
        render-markdown-nvim
      ];
      
      # Git integration
      gitPackages = with pkgs.vimPlugins; [
        neogit
        diffview-nvim
        octo-nvim
      ];
      
      # Editor enhancements
      editorPackages = with pkgs.vimPlugins; [
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
        claudecode-nvim
      ];
      
      # Treesitter and syntax
      treesitterPackages = with pkgs.vimPlugins; [
        nvim-treesitter
      ];
      
      # Debug support
      debugPackages = with pkgs.vimPlugins; [
        nvim-dap
        nvim-dap-ui
        nvim-nio
        mason-nvim-dap-nvim
        nvim-dap-go
      ];
      
      # Dependencies
      dependencies = with pkgs.vimPlugins; [
        plenary-nvim
        telescope-nvim
        noice-nvim  # optional dependency
        markdown-preview-nvim
      ];
      
      # Plugins not in nixpkgs - will be loaded by lazy.nvim
      lazyPlugins = [
        # Add the missing multiple-cursors plugin here if needed
      ];
    };

    packageDefinitions = {
      nvim = { pkgs, ... }: {
        settings = {
          wrapRc = true;
          configDirName = "nvim-nixcats";
          vimAlias = false;
          viAlias = false;
        };
        categories = {
          # Enable all our plugin categories
          lspPackages = true;
          completionPackages = true;
          uiPackages = true;
          gitPackages = true;
          editorPackages = true;
          treesitterPackages = true;
          debugPackages = true;
          dependencies = true;
          
          # System tools
          general = {
            extra_pkg_config = {
              # LSP servers
              lua-language-server = pkgs.lua-language-server;
              nixd = pkgs.nixd;
              nil = pkgs.nil;
              bash-language-server = pkgs.nodePackages.bash-language-server;
              yaml-language-server = pkgs.nodePackages.yaml-language-server;
              rust-analyzer = pkgs.rust-analyzer;
              gopls = pkgs.gopls;
              pyright = pkgs.pyright;
              clang-tools = pkgs.clang-tools;
              taplo = pkgs.taplo;
              marksman = pkgs.marksman;
              vtsls = pkgs.vtsls;
              
              # Formatters
              stylua = pkgs.stylua;
              prettierd = pkgs.prettierd;
              
              # Core tools
              git = pkgs.git;
              ripgrep = pkgs.ripgrep;
              fd = pkgs.fd;
              unzip = pkgs.unzip;
            };
          };
        };
      };
    };
  in
  forEachSystem (system: let
    nixCatsBuilder = nixCats.utils.makePackageWithName luaPath;
  in {
    packages = nixCatsBuilder categoryDefinitions packageDefinitions pkgs.nixpkgs system;
    
    # Development shell with nixCats nvim
    devShells.default = let
      pkgs = nixpkgs.legacyPackages.${system};
      nvim-pkg = nixCatsBuilder categoryDefinitions packageDefinitions pkgs.nixpkgs system;
    in pkgs.mkShell {
      packages = [ nvim-pkg.nvim ];
      shellHook = ''
        echo "nixCats Neovim loaded with all plugins via Nix!"
      '';
    };
  });
}