return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile' },
  -- Don't run TSUpdate since we use Nix-provided parsers
  build = false,
  opts = {
    -- Use only Nix-provided parsers, disable installation
    ensure_installed = {},
    auto_install = false,

    highlight = {
      enable = true,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },

    -- Incremental selection based on treesitter
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<M-o>',    -- Start selection with Alt+O
        node_incremental = '<M-o>',  -- Expand with Alt+O
        node_decremental = '<M-i>',  -- Shrink with Alt+I
        scope_incremental = '<M-n>', -- Expand scope with Alt+N
      },
    },
  },
  config = function(_, opts)
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

    ---@diagnostic disable-next-line: missing-fields
    require('nvim-treesitter.configs').setup(opts)


    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Configured above, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  end,
}
