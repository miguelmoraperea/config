local M = {}

local review_state = {
    active = false,
    original_cwd = nil,
    worktree_path = nil,
    pr_number = nil,
    branch_name = nil,
    keep_worktree = false,
    diffview_cmd = nil,
}

local function get_repo_root()
    local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+", "")
    if vim.v.shell_error ~= 0 or root == "" then
        return nil
    end
    return root
end

local function get_repo_name(repo_root)
    return vim.fn.fnamemodify(repo_root, ":t")
end

local function get_main_branch()
    local main_branch = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"):gsub("%s+", "")
    if main_branch == "" then
        main_branch = "main"
    end
    return main_branch
end

local function reset_state()
    review_state.active = false
    review_state.original_cwd = nil
    review_state.worktree_path = nil
    review_state.pr_number = nil
    review_state.branch_name = nil
    review_state.keep_worktree = false
    review_state.diffview_cmd = nil
end

function M.start_review(pr_number)
    if review_state.active then
        vim.notify(
            string.format("Review already active for PR #%s. End it first with :TeamPREnd", review_state.pr_number),
            vim.log.levels.WARN
        )
        return
    end

    local repo_root = get_repo_root()
    if not repo_root then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end

    local repo_name = get_repo_name(repo_root)
    local repo_parent = vim.fn.fnamemodify(repo_root, ":h")
    local branch_name = "pr-" .. pr_number
    local worktree_parent = repo_parent .. "/" .. repo_name .. "-worktrees"
    local worktree_path = worktree_parent .. "/" .. branch_name

    -- Check if worktree already exists
    local existing = vim.fn.isdirectory(worktree_path)
    if existing == 1 then
        vim.notify("Worktree already exists at " .. worktree_path .. ". Removing it first.", vim.log.levels.INFO)
        vim.fn.system(string.format("git -C %s worktree remove %s --force 2>&1",
            vim.fn.shellescape(repo_root),
            vim.fn.shellescape(worktree_path)))
        vim.fn.system(string.format("git -C %s branch -D %s 2>&1",
            vim.fn.shellescape(repo_root),
            vim.fn.shellescape(branch_name)))
    end

    -- Compute relative path from repo root to current working directory
    -- e.g., in World: "areas/platforms/harvester"
    local cwd = vim.fn.getcwd()
    local relative_path = nil
    if #cwd > #repo_root then
        relative_path = cwd:sub(#repo_root + 2) -- +2 to skip the trailing /
    end

    -- Store state before any changes
    review_state.original_cwd = cwd
    review_state.pr_number = pr_number
    review_state.branch_name = branch_name

    -- Create worktree parent directory
    vim.fn.mkdir(worktree_parent, "p")

    -- Fetch the PR branch
    vim.notify(string.format("Fetching PR #%s...", pr_number), vim.log.levels.INFO)
    local fetch_result = vim.fn.system(
        string.format("git -C %s fetch origin pull/%s/head:%s 2>&1",
            vim.fn.shellescape(repo_root), pr_number, branch_name)
    )
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to fetch PR: " .. fetch_result, vim.log.levels.ERROR)
        reset_state()
        return
    end

    -- Create the worktree
    vim.notify("Creating worktree...", vim.log.levels.INFO)
    local worktree_result = vim.fn.system(
        string.format("git -C %s worktree add %s %s 2>&1",
            vim.fn.shellescape(repo_root),
            vim.fn.shellescape(worktree_path),
            branch_name)
    )
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to create worktree: " .. worktree_result, vim.log.levels.ERROR)
        -- Clean up the fetched branch
        vim.fn.system(string.format("git -C %s branch -D %s 2>&1",
            vim.fn.shellescape(repo_root), branch_name))
        reset_state()
        return
    end

    review_state.worktree_path = worktree_path
    review_state.active = true

    -- Change Neovim working directory to the worktree root
    -- (stay at root so diffview path filters resolve correctly against git root)
    vim.cmd("cd " .. vim.fn.fnameescape(worktree_path))

    -- Compute merge base and open diffview, scoped to the relative path
    local main_branch = get_main_branch()
    local merge_base = vim.fn.system(
        string.format("git merge-base HEAD origin/%s 2>/dev/null", main_branch)
    ):gsub("%s+", "")

    local diffview_cmd
    local path_filter = relative_path and (" -- " .. relative_path) or ""
    if merge_base == "" then
        vim.notify("Could not determine merge base. Opening diffview against HEAD~1.", vim.log.levels.WARN)
        diffview_cmd = "DiffviewOpen HEAD~1" .. path_filter
    else
        diffview_cmd = "DiffviewOpen " .. merge_base .. "..HEAD" .. path_filter
    end
    review_state.diffview_cmd = diffview_cmd
    vim.cmd(diffview_cmd)

    vim.notify(
        string.format("Reviewing PR #%s in worktree. Close diffview to end review.", pr_number),
        vim.log.levels.INFO
    )
end

function M.end_review()
    if not review_state.active then
        vim.notify("No active review to end", vim.log.levels.INFO)
        return
    end

    if review_state.keep_worktree then
        -- Keep review state active so diffview can be reopened
        review_state.keep_worktree = false
        vim.notify(
            string.format("Diffview closed. Worktree kept. Use :TeamPRReopen to reopen, :TeamPREnd to clean up.", review_state.pr_number),
            vim.log.levels.INFO
        )
        return
    end

    local pr_number = review_state.pr_number
    local worktree_path = review_state.worktree_path
    local branch_name = review_state.branch_name
    local original_cwd = review_state.original_cwd

    -- Find the main repo root (parent of worktrees dir)
    local worktree_parent = vim.fn.fnamemodify(worktree_path, ":h")
    local repo_name = vim.fn.fnamemodify(worktree_parent, ":t"):gsub("%-worktrees$", "")
    local repo_parent = vim.fn.fnamemodify(worktree_parent, ":h")
    local repo_root = repo_parent .. "/" .. repo_name

    -- Change back to original directory first (can't remove a worktree while inside it)
    vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))

    -- Remove worktree
    local remove_result = vim.fn.system(
        string.format("git -C %s worktree remove %s --force 2>&1",
            vim.fn.shellescape(repo_root),
            vim.fn.shellescape(worktree_path))
    )
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to remove worktree: " .. remove_result, vim.log.levels.WARN)
    end

    -- Delete the local branch
    vim.fn.system(string.format("git -C %s branch -D %s 2>&1",
        vim.fn.shellescape(repo_root), branch_name))

    -- Prune worktree references
    vim.fn.system(string.format("git -C %s worktree prune 2>&1",
        vim.fn.shellescape(repo_root)))

    reset_state()

    vim.notify(string.format("Review of PR #%s ended. Worktree cleaned up.", pr_number), vim.log.levels.INFO)
end

function M.keep_worktree()
    review_state.keep_worktree = true
end

function M.reopen_diffview()
    if not review_state.active then
        vim.notify("No active review", vim.log.levels.INFO)
        return
    end
    if not review_state.diffview_cmd then
        vim.notify("No diffview command stored", vim.log.levels.ERROR)
        return
    end
    vim.cmd(review_state.diffview_cmd)
end

function M.is_active()
    return review_state.active
end

function M.get_status()
    if not review_state.active then
        vim.notify("No active review", vim.log.levels.INFO)
        return
    end

    local lines = {
        "PR Review Status:",
        "  PR: #" .. tostring(review_state.pr_number),
        "  Branch: " .. (review_state.branch_name or "unknown"),
        "  Worktree: " .. (review_state.worktree_path or "unknown"),
        "  Original cwd: " .. (review_state.original_cwd or "unknown"),
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.setup()
    vim.api.nvim_create_user_command('TeamPREnd', M.end_review, {
        desc = 'End active PR review and clean up worktree'
    })

    vim.api.nvim_create_user_command('TeamPRStatus', M.get_status, {
        desc = 'Show active PR review status'
    })

    vim.api.nvim_create_user_command('TeamPRReopen', M.reopen_diffview, {
        desc = 'Reopen diffview for active PR review'
    })
end

return M
