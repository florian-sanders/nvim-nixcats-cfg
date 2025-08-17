-- NOTE: nixCats: nixd is not available on mason.
-- Feel free to check the nixd docs for more configuration options:
-- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md

-- Only enable nixd if we're using nixCats
if not require('nixCatsUtils').isNixCats then
  return nil
end

return {
  settings = {
    nixd = {
      nixpkgs = {
        -- in the extras set of your package definition:
        -- nixdExtras.nixpkgs = ''import ${pkgs.path} {}''
        expr = nixCats.extra 'nixdExtras.nixpkgs' or [[import <nixpkgs> {}]],
      },
      options = {
        -- If you integrated with your system flake,
        -- you should use inputs.self as the path to your system flake
        -- that way it will ALWAYS work, regardless
        -- of where your config actually was.
        nixos = {
          -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
          expr = nixCats.extra 'nixdExtras.nixos_options',
        },
        -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
        -- You can override the correct one into your package definition on import in your main configuration,
        -- or just put an absolute path to where it usually is and accept the impurity.
        ['home-manager'] = {
          -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
          expr = nixCats.extra 'nixdExtras.home_manager_options',
        },
      },
      formatting = {
        command = { 'nixfmt' },
      },
      diagnostic = {
        suppress = {
          'sema-escaping-with',
        },
      },
    },
  },
}