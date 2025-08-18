#!/run/current-system/sw/bin/bash

# Profile Nix-based config
echo "=== Profiling Nix-based Config ==="

# Ensure we're in the nix develop environment
if [ -z "$IN_NIX_SHELL" ]; then
    echo "Not in nix shell, entering nix develop..."
    nix develop --command bash -c "$(cat <<'EOF'
        cd /home/flo-perso-workstation/Projects/nvim-nixcats-cfg
        nvim --headless --startuptime /tmp/nix_startuptime.log -c "lua dofile('$(pwd)/compare-plugins.lua').save_profile('nix')" -c "sleep 500m" -c "qa!"
        echo "Nix config profiling complete!"
        echo "Startup time log: /tmp/nix_startuptime.log"
        echo "Plugin analysis: /tmp/nvim_profile_nix.txt"
        echo ""
        
        # Extract key metrics
        if [ -f /tmp/nix_startuptime.log ]; then
            echo "=== Nix-based Config Startup Summary ==="
            tail -1 /tmp/nix_startuptime.log | grep -o '[0-9.]*: sourcing'
            wc -l /tmp/nix_startuptime.log | awk '{print "Total startup events:", $1}'
        fi
EOF
    )"
else
    cd /home/flo-perso-workstation/Projects/nvim-nixcats-cfg
    nvim --headless --startuptime /tmp/nix_startuptime.log -c "lua dofile('$(pwd)/compare-plugins.lua').save_profile('nix')" -c "sleep 500m" -c "qa!"
    
    echo "Nix config profiling complete!"
    echo "Startup time log: /tmp/nix_startuptime.log" 
    echo "Plugin analysis: /tmp/nvim_profile_nix.txt"
    echo ""
    
    # Extract key metrics
    if [ -f /tmp/nix_startuptime.log ]; then
        echo "=== Nix-based Config Startup Summary ==="
        tail -1 /tmp/nix_startuptime.log | grep -o '[0-9.]*: sourcing'
        wc -l /tmp/nix_startuptime.log | awk '{print "Total startup events:", $1}'
    fi
fi