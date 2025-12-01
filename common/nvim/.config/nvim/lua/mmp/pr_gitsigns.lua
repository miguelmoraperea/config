local M = {}

-- State to track if we're in PR diff mode
local pr_diff_mode = false

-- Function to get the main/master branch name
local function get_main_branch()
    local main_branch = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"):gsub("%s+", "")
    if main_branch == "" then
        main_branch = "main"  -- fallback to main
    end
    return main_branch
end

-- Function to get current branch name
local function get_current_branch()
    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+", "")
    if vim.v.shell_error ~= 0 or branch == "" then
        return nil
    end
    return branch
end

-- Function to check if current branch is a PR branch
local function is_pr_branch()
    local current_branch = get_current_branch()
    if not current_branch then
        return false
    end
    
    local main_branch = get_main_branch()
    -- Consider it a PR branch if it's not main/master and not HEAD
    return current_branch ~= main_branch and current_branch ~= "master" and current_branch ~= "HEAD"
end

-- Function to get merge base with main branch
local function get_merge_base()
    local main_branch = get_main_branch()
    local merge_base = vim.fn.system("git merge-base HEAD origin/" .. main_branch .. " 2>/dev/null"):gsub("%s+", "")
    if vim.v.shell_error ~= 0 or merge_base == "" then
        return nil
    end
    return merge_base
end

-- Function to enable PR diff mode
function M.enable_pr_diff_mode()
    if pr_diff_mode then
        vim.notify("PR diff mode already enabled", vim.log.levels.INFO)
        return
    end
    
    if not is_pr_branch() then
        vim.notify("Not on a PR branch", vim.log.levels.WARN)
        return
    end
    
    local merge_base = get_merge_base()
    if not merge_base then
        vim.notify("Could not determine merge base", vim.log.levels.ERROR)
        return
    end
    
    -- gitsigns defaults to HEAD when base is nil
    
    -- Set gitsigns to compare against merge base
    local ok, gitsigns = pcall(require, 'gitsigns')
    if not ok then
        vim.notify("Gitsigns not available", vim.log.levels.ERROR)
        return
    end
    
    local success, err = pcall(gitsigns.change_base, merge_base, true)
    if not success then
        vim.notify("Failed to change gitsigns base: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    
    pr_diff_mode = true
    
    local current_branch = get_current_branch()
    vim.notify(string.format("PR diff mode enabled: comparing %s against %s", current_branch, merge_base:sub(1, 8)), vim.log.levels.INFO)
end

-- Function to disable PR diff mode
function M.disable_pr_diff_mode()
    if not pr_diff_mode then
        vim.notify("PR diff mode not enabled", vim.log.levels.INFO)
        return
    end
    
    local ok, gitsigns = pcall(require, 'gitsigns')
    if not ok then
        vim.notify("Gitsigns not available", vim.log.levels.ERROR)
        return
    end
    
    -- Restore to HEAD comparison (nil base)
    local success, err = pcall(gitsigns.change_base, nil, true)
    if not success then
        vim.notify("Failed to restore gitsigns base: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    
    pr_diff_mode = false
    
    vim.notify("PR diff mode disabled: back to HEAD comparison", vim.log.levels.INFO)
end

-- Function to toggle PR diff mode
function M.toggle_pr_diff_mode()
    if pr_diff_mode then
        M.disable_pr_diff_mode()
    else
        M.enable_pr_diff_mode()
    end
end

-- Function to auto-enable PR diff mode if conditions are met
function M.auto_enable_pr_diff_mode()
    if is_pr_branch() then
        -- Add a small delay to ensure gitsigns is fully loaded
        vim.defer_fn(function()
            M.enable_pr_diff_mode()
        end, 500)
    end
end

-- Function to get current status
function M.get_status()
    local current_branch = get_current_branch()
    local main_branch = get_main_branch()
    
    return {
        pr_diff_mode = pr_diff_mode,
        current_branch = current_branch,
        main_branch = main_branch,
        is_pr_branch = is_pr_branch(),
        merge_base = pr_diff_mode and get_merge_base() or nil
    }
end

-- Function to show current status
function M.show_status()
    local status = M.get_status()
    
    local lines = {
        "PR GitSigns Status:",
        "  Current branch: " .. (status.current_branch or "unknown"),
        "  Main branch: " .. status.main_branch,
        "  Is PR branch: " .. tostring(status.is_pr_branch),
        "  PR diff mode: " .. tostring(status.pr_diff_mode),
    }
    
    if status.pr_diff_mode and status.merge_base then
        table.insert(lines, "  Comparing against: " .. status.merge_base:sub(1, 8))
    end
    
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Hook for diffview close to auto-enable PR diff mode
function M.on_diffview_close()
    -- Small delay to ensure diffview is fully closed
    vim.defer_fn(function()
        if is_pr_branch() then
            M.enable_pr_diff_mode()
        end
    end, 100)
end

-- Setup function to initialize the module
function M.setup()
    -- Check if gitsigns is available
    local ok, gitsigns = pcall(require, 'gitsigns')
    if not ok then
        vim.notify("Gitsigns not available, PR diff mode disabled", vim.log.levels.WARN)
        return
    end
    
    -- Create user commands
    vim.api.nvim_create_user_command('PRDiffEnable', M.enable_pr_diff_mode, {
        desc = 'Enable PR diff mode (compare against merge base)'
    })
    
    vim.api.nvim_create_user_command('PRDiffDisable', M.disable_pr_diff_mode, {
        desc = 'Disable PR diff mode (compare against HEAD)'
    })
    
    vim.api.nvim_create_user_command('PRDiffToggle', M.toggle_pr_diff_mode, {
        desc = 'Toggle PR diff mode'
    })
    
    vim.api.nvim_create_user_command('PRDiffStatus', M.show_status, {
        desc = 'Show PR diff mode status'
    })
    
    vim.api.nvim_create_user_command('PRDiffTest', function()
        local ok, gitsigns = pcall(require, 'gitsigns')
        if ok then
            vim.notify("Gitsigns is available", vim.log.levels.INFO)
            -- Test if change_base exists
            if type(gitsigns.change_base) == "function" then
                vim.notify("change_base function is available", vim.log.levels.INFO)
            else
                vim.notify("change_base function is NOT available", vim.log.levels.ERROR)
            end
        else
            vim.notify("Gitsigns is NOT available", vim.log.levels.ERROR)
        end
    end, {
        desc = 'Test PR diff functionality'
    })
    
    -- Auto-enable when switching to PR branches
    vim.api.nvim_create_autocmd({'BufEnter', 'FocusGained'}, {
        callback = function()
            -- Only auto-enable if we're not already in PR diff mode and we're on a PR branch
            if not pr_diff_mode and is_pr_branch() then
                -- Check if we just switched branches by comparing with a stored value
                local current_branch = get_current_branch()
                if vim.g.last_branch ~= current_branch then
                    vim.g.last_branch = current_branch
                    -- Small delay to ensure git operations are complete and gitsigns is loaded
                    vim.defer_fn(function()
                        -- Double-check gitsigns is available before enabling
                        local ok, _ = pcall(require, 'gitsigns')
                        if ok then
                            M.enable_pr_diff_mode()
                        end
                    end, 500)
                end
            end
        end,
    })
    
    -- Disable PR diff mode when switching to main/master
    vim.api.nvim_create_autocmd({'BufEnter'}, {
        callback = function()
            local current_branch = get_current_branch()
            local main_branch = get_main_branch()
            
            if pr_diff_mode and (current_branch == main_branch or current_branch == "master") then
                M.disable_pr_diff_mode()
            end
        end,
    })
end

return M
