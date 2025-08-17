-- nixd LSP for Nix
-- Feel free to check the nixd docs for more configuration options:
-- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md

return {
  settings = {
    nixd = {
      nixpkgs = {
        expr = [[import <nixpkgs> {}]],
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