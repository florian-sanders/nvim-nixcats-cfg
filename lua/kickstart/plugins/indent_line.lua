return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- NOTE: nixCats: return true only if category is enabled, else false
    enabled = false, -- Disabled in favor of Snacks indent
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
      },
      indent = {
        char = "┊", -- Dotted line (most subtle)
        -- char = "▏", -- Very thin line
        -- char = "╎", -- Dashed line
        -- char = "⋅", -- Centered dot
        -- char = "·", -- Middle dot
      },
    },
  },
}
