#!/run/current-system/sw/bin/bash

# Compare both configurations
echo "=== Neovim Configuration Comparison ==="
echo ""

# Make scripts executable
chmod +x profile-regular.sh profile-nix.sh

# Run both profiles
./profile-regular.sh
echo ""
./profile-nix.sh
echo ""

echo "=== COMPARISON RESULTS ==="
echo ""

# Compare startup times
if [ -f /tmp/regular_startuptime.log ] && [ -f /tmp/nix_startuptime.log ]; then
    regular_time=$(tail -1 /tmp/regular_startuptime.log | grep -o '^[0-9.]*')
    nix_time=$(tail -1 /tmp/nix_startuptime.log | grep -o '^[0-9.]*')
    
    echo "Regular LazyVim startup time: ${regular_time}ms"
    echo "Nix-based config startup time: ${nix_time}ms"
    
    if [ -n "$regular_time" ] && [ -n "$nix_time" ]; then
        difference=$(echo "$nix_time - $regular_time" | bc)
        echo "Difference: ${difference}ms (Nix config is $(echo "$difference > 0" | bc -l) && echo "slower" || echo "faster")"
    fi
    echo ""
fi

# Show detailed plugin analyses
if [ -f /tmp/nvim_profile_regular.txt ]; then
    echo "=== Regular LazyVim Plugin Analysis ==="
    cat /tmp/nvim_profile_regular.txt
    echo ""
fi

if [ -f /tmp/nvim_profile_nix.txt ]; then
    echo "=== Nix-based Config Plugin Analysis ==="
    cat /tmp/nvim_profile_nix.txt
    echo ""
fi

# Compare startup event counts
regular_events=$(wc -l < /tmp/regular_startuptime.log 2>/dev/null || echo 0)
nix_events=$(wc -l < /tmp/nix_startuptime.log 2>/dev/null || echo 0)

echo "Startup events comparison:"
echo "  Regular LazyVim: $regular_events events"
echo "  Nix-based: $nix_events events"
echo "  Difference: $((nix_events - regular_events)) events"