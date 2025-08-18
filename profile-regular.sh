#!/run/current-system/sw/bin/bash

# Profile regular LazyVim config
echo "=== Profiling Regular LazyVim Config ==="

export NVIM_APPNAME="nvim"

# Run with startup profiling
nvim --headless --startuptime /tmp/regular_startuptime.log -c "lua dofile('$(pwd)/compare-plugins.lua').save_profile('regular')" -c "sleep 500m" -c "qa!"

echo "Regular config profiling complete!"
echo "Startup time log: /tmp/regular_startuptime.log"
echo "Plugin analysis: /tmp/nvim_profile_regular.txt"
echo ""

# Extract key metrics
if [ -f /tmp/regular_startuptime.log ]; then
    echo "=== Regular LazyVim Startup Summary ==="
    tail -1 /tmp/regular_startuptime.log | grep -o '[0-9.]*: sourcing'
    wc -l /tmp/regular_startuptime.log | awk '{print "Total startup events:", $1}'
fi