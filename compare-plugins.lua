-- Neovim startup profiler script to compare plugin loading
-- This should be placed in your Neovim config and run via --startuptime

local M = {}

function M.profile_startup()
    local start_time = vim.loop.hrtime()
    local plugin_times = {}
    local lazy_stats = {}
    
    -- Hook into vim.loader if available (Neovim 0.9+)
    if vim.loader then
        local original_load = vim.loader.load
        vim.loader.load = function(modname, opts)
            local load_start = vim.loop.hrtime()
            local result = original_load(modname, opts)
            local load_time = (vim.loop.hrtime() - load_start) / 1000000 -- Convert to ms
            
            if load_time > 0.1 then -- Only track significant loads
                plugin_times[modname] = (plugin_times[modname] or 0) + load_time
            end
            
            return result
        end
    end
    
    -- Get Lazy.nvim stats if available
    vim.defer_fn(function()
        if package.loaded['lazy'] then
            local lazy = require('lazy')
            local plugins = lazy.plugins()
            
            print("\n=== LAZY.NVIM PLUGIN STATUS ===")
            print(string.format("Total plugins: %d", #plugins))
            
            local loaded_count = 0
            local lazy_count = 0
            
            for _, plugin in pairs(plugins) do
                if plugin._.loaded then
                    loaded_count = loaded_count + 1
                    print(string.format("✓ LOADED: %s", plugin.name))
                else
                    lazy_count = lazy_count + 1
                    local events = "none"
                    if plugin.event then
                        if type(plugin.event) == "table" then
                            events = table.concat(plugin.event, ", ")
                        else
                            events = tostring(plugin.event)
                        end
                    end
                    print(string.format("⏳ LAZY: %s (events: %s)", plugin.name, events))
                end
            end
            
            print(string.format("\nSummary: %d loaded, %d lazy-loaded", loaded_count, lazy_count))
            
            -- Get detailed stats
            local stats = lazy.stats()
            print("\n=== LAZY.NVIM STATS ===")
            print(string.format("Startup time: %.2fms", stats.startuptime))
            print(string.format("Loaded plugins: %d/%d", stats.loaded, stats.count))
            
            lazy_stats = stats
        end
        
        local total_time = (vim.loop.hrtime() - start_time) / 1000000
        print(string.format("\n=== TOTAL STARTUP TIME: %.2fms ===", total_time))
        
        -- Print module load times
        if next(plugin_times) then
            print("\n=== MODULE LOAD TIMES ===")
            local sorted_times = {}
            for module, time in pairs(plugin_times) do
                table.insert(sorted_times, {module, time})
            end
            table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
            
            for _, entry in ipairs(sorted_times) do
                print(string.format("%.2fms - %s", entry[2], entry[1]))
            end
        end
    end, 100) -- Small delay to let everything load
end

function M.save_profile(config_name)
    local profile_file = string.format("/tmp/nvim_profile_%s.txt", config_name)
    vim.cmd("redir! > " .. profile_file)
    M.profile_startup()
    vim.defer_fn(function()
        vim.cmd("redir END")
        print("Profile saved to: " .. profile_file)
    end, 200)
end

-- Auto-run profiling if this script is sourced
M.profile_startup()

return M