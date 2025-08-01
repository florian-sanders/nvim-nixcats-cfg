# AGENTS.md

## Development Commands

- **Dev Shell:**  
  `nix develop`  
  Enters a shell with all runtime dependencies.

- **Format Lua:**  
  Use [Stylua](https://github.com/JohnnyMorganz/StyLua) (config in `.stylua.toml`):  
  `stylua .`  
  (Stylua is included in the Nix dev shell.)

- **Note:** Build commands are handled by the user - agents should not run `nix build` or similar build commands.

## Code Style Guidelines

- **Formatting:**  
  - Use 2 spaces for indentation (`indent_width = 2`).
  - Prefer single quotes for strings.
  - Max line width: 160 chars.
  - No trailing whitespace; Unix line endings.

- **Imports:**  
  - Use `require('module')` for Lua modules.
  - Modularize plugins in `lua/custom/plugins/`.

- **Naming:**  
  - Use `snake_case` for variables and functions.
  - Use `PascalCase` for modules.

- **Types:**  
  - Lua is dynamically typed; use clear variable names and comments for type hints.

- **Error Handling:**  
  - Use `pcall` for safe module loading.
  - Prefer explicit error messages.

- **Comments:**  
  - Use `-- NOTE: nixCats:` for NixCats-specific notes.
  - Document key sections and custom logic.

- **General:**  
  - Keep configuration modular (see `init.lua` and plugin folders).
  - Use `nixCats` for passing Nix values to Lua.
  - Avoid global variables unless necessary.

---

If you add Cursor or Copilot rules, update this file to include their agent instructions.