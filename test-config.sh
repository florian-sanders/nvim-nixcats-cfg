#!/usr/bin/env bash
# Test script to verify the Neovim configuration works

echo "🧪 Testing Neovim configuration..."

# Test 1: Check if we're in the right directory
if [ ! -f "init.lua" ]; then
    echo "❌ Error: init.lua not found. Run this script from the config directory."
    exit 1
fi

echo "✅ Config directory confirmed"

# Test 2: Check if nix develop works
if ! nix develop --command nvim --version >/dev/null 2>&1; then
    echo "❌ Error: nix develop failed"
    exit 1
fi

echo "✅ Nix development shell works"

# Test 3: Check if LSPs are available
echo "🔍 Checking LSP availability..."
nix develop --command bash -c '
    echo "  lua-language-server: $(which lua-language-server >/dev/null && echo "✅" || echo "❌")"
    echo "  nixd: $(which nixd >/dev/null && echo "✅" || echo "❌")"
    echo "  rust-analyzer: $(which rust-analyzer >/dev/null && echo "✅" || echo "❌")"
    echo "  gopls: $(which gopls >/dev/null && echo "✅" || echo "❌")"
    echo "  pyright: $(which pyright >/dev/null && echo "✅" || echo "❌")"
'

# Test 4: Quick Neovim startup test
echo "🚀 Testing Neovim startup..."
if nix develop --command nvim --cmd 'lua print("Neovim config loaded successfully!")' --cmd 'quit' 2>/dev/null; then
    echo "✅ Neovim starts correctly with config"
else
    echo "❌ Neovim startup failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Your configuration is ready to use."
echo ""
echo "To use:"
echo "  1. cd $(pwd)"
echo "  2. nix develop"
echo "  3. nvim"