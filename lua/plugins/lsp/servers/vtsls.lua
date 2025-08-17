return {
  settings = {
    typescript = {
      tsserver = {
        maxTsServerMemory = 8192,
      },
      preferences = {
        includePackageJsonAutoImports = 'off',
        importModuleSpecifier = 'project-relative',
        importModuleSpecifierEnding = 'js',
      },
    },
    javascript = {
      tsserver = {
        maxTsServerMemory = 8192,
      },
      preferences = {
        includePackageJsonAutoImports = 'off',
        importModuleSpecifier = 'project-relative',
        importModuleSpecifierEnding = 'js',
      },
    },
    experimental = {
      completion = {
        enableServerSideFuzzyMatch = true,
        entriesLimit = 50,
      },
    },
  },
}