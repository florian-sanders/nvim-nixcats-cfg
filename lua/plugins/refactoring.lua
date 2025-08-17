return {
  'ThePrimeagen/refactoring.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    prompt_func_return_type = {
      go = false,
      java = false,
      cpp = false,
      c = false,
      h = false,
      hpp = false,
      cxx = false,
    },
    prompt_func_param_type = {
      go = false,
      java = false,
      cpp = false,
      c = false,
      h = false,
      hpp = false,
      cxx = false,
    },
    printf_statements = {},
    print_var_statements = {},
    show_success_message = true,
  },
  config = function(_, opts)
    require('refactoring').setup(opts)

    -- Use snacks for UI components
    local snacks_ok, snacks = pcall(require, 'snacks')
    if snacks_ok then
      -- Override default input/select with snacks
      vim.ui.select = snacks.picker.pick_one or vim.ui.select
      vim.ui.input = snacks.input or vim.ui.input
    end
  end,
  keys = {
    -- Extract function supports only visual mode
    {
      '<leader>re',
      function()
        require('refactoring').refactor('Extract Function')
      end,
      mode = 'x',
      desc = 'Extract Function',
    },
    {
      '<leader>rf',
      function()
        require('refactoring').refactor('Extract Function To File')
      end,
      mode = 'x',
      desc = 'Extract Function To File',
    },
    -- Extract variable supports only visual mode
    {
      '<leader>rv',
      function()
        require('refactoring').refactor('Extract Variable')
      end,
      mode = 'x',
      desc = 'Extract Variable',
    },
    -- Inline variable supports both normal and visual mode
    {
      '<leader>ri',
      function()
        require('refactoring').refactor('Inline Variable')
      end,
      mode = { 'n', 'x' },
      desc = 'Inline Variable',
    },
    -- Extract block supports only visual mode
    {
      '<leader>rb',
      function()
        require('refactoring').refactor('Extract Block')
      end,
      mode = 'x',
      desc = 'Extract Block',
    },
    {
      '<leader>rbf',
      function()
        require('refactoring').refactor('Extract Block To File')
      end,
      mode = 'x',
      desc = 'Extract Block To File',
    },
    -- Debug print var
    {
      '<leader>rp',
      function()
        require('refactoring').debug.print_var()
      end,
      mode = { 'x', 'n' },
      desc = 'Debug Print Variable',
    },
    -- Debug cleanup
    {
      '<leader>rc',
      function()
        require('refactoring').debug.cleanup {}
      end,
      desc = 'Debug Cleanup',
    },
    -- Refactoring menu with snacks picker
    {
      '<leader>rr',
      function()
        local snacks_ok, snacks = pcall(require, 'snacks')
        if snacks_ok and snacks.picker then
          -- Create custom picker for refactoring options
          local refactoring_options = {
            { name = 'Extract Function', value = 'Extract Function', mode = 'x' },
            { name = 'Extract Function To File', value = 'Extract Function To File', mode = 'x' },
            { name = 'Extract Variable', value = 'Extract Variable', mode = 'x' },
            { name = 'Extract Block', value = 'Extract Block', mode = 'x' },
            { name = 'Extract Block To File', value = 'Extract Block To File', mode = 'x' },
            { name = 'Inline Variable', value = 'Inline Variable', mode = 'both' },
          }
          
          local current_mode = vim.fn.mode()
          local filtered_options = {}
          
          for _, option in ipairs(refactoring_options) do
            if option.mode == 'both' or 
               (option.mode == 'x' and current_mode:match('[vVsS]')) or
               (option.mode == 'n' and current_mode == 'n') then
              table.insert(filtered_options, option)
            end
          end
          
          vim.ui.select(filtered_options, {
            prompt = 'Select refactoring:',
            format_item = function(item) return item.name end,
          }, function(choice)
            if choice then
              require('refactoring').refactor(choice.value)
            end
          end)
        else
          -- Fallback to default refactoring menu
          require('refactoring').select_refactor()
        end
      end,
      mode = { 'n', 'x' },
      desc = 'Refactoring Menu',
    },
  },
}