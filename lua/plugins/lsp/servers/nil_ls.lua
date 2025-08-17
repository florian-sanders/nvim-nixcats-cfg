-- nil_ls LSP for Nix (used when not using nixCats)

-- Only enable nil_ls if we're NOT using nixCats
if require('nixCatsUtils').isNixCats then
  return nil
end

return {}