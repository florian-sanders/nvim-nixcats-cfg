-- rnix LSP for Nix (used when not using nixCats)

-- Only enable rnix if we're NOT using nixCats
if require('nixCatsUtils').isNixCats then
  return nil
end

return {}