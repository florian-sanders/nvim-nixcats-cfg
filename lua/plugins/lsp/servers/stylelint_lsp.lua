-- Only enable stylelint_lsp if we're using nixCats
if not require('nixCatsUtils').isNixCats then
  return nil
end

return {
  cmd = { 'stylelint-lsp', '--stdio' },
  filetypes = { 'css', 'less', 'scss', 'sugarss', 'vue', 'wxss', 'javascript', 'typescript' },
  root_dir = function(fname)
    return vim.fs.dirname(vim.fs.find({
      '.stylelintrc',
      '.stylelintrc.json',
      '.stylelintrc.yaml',
      '.stylelintrc.yml',
      '.stylelintrc.js',
      '.stylelintrc.mjs',
      'stylelint.config.js',
      'stylelint.config.mjs',
      'package.json',
    }, { upward = true, path = tostring(fname) })[1])
  end,
  settings = {
    stylelint = {
      ignoreDisables = false,
      packageManager = 'npm',
      snippet = { 'css', 'postcss' },
    },
  },
}