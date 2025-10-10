local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope.utils")
local entry_display = require("telescope.pickers.entry_display")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

require("telescope").setup({
    defaults = {
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
        },
        prompt_prefix = "> ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "vertical",
        layout_config = {
            horizontal = {
                width = 0.75,
                prompt_position = "top",
                preview_cutoff = 120,
            },
            vertical = {
                width = 0.7,
            },
        },
        file_sorter = require("telescope.sorters").get_fzy_sorter,
        file_ignore_patterns = {
            "%.git",
            "releases",
            "__pycache__",
            "venv",
            "^.null-ls*",
            "build",
            "main/conf",
            "main/assembly",
        },
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        path_display = {},
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        use_less = true,
        set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
    },
    extensions = {
        fzy_native = {
            override_generic_sorter = true,
            override_file_sorter = true,
        },
        project = {
            base_dirs = {
                "~/Desktop/git",
            },
            hidden_files = true,
            theme = "dropdown",
            order_by = "ascending",
            search_by = "title",
            sync_with_nvim_tree = false,
        },
        tmuxdir = {
         base_dirs = {
             "~/Desktop",
             "~/Desktop/git",
             "~/Desktop/git/config/common",
         },
         find_cmd = {"find", "-mindepth", "1", "-maxdepth", "1", "-type", "d"},
        -- selected=$(find ~/Desktop ~/Desktop/git ~/Desktop/p4 ~/Desktop/p4/ml/apps/services ~/Desktop/git/config/common -mindepth 1 -maxdepth 1 -type d | fzf)
       },
    },
})

require("telescope").load_extension("fzy_native")
require("telescope").load_extension("ui-select")
require("telescope").load_extension("project")
require('telescope').load_extension('fzy_native')
-- require('telescope').load_extension("ui-select")

local M = {}

M.search_dotfiles = function()
    require("telescope.builtin").find_files({
        prompt_title = "< VimRC >",
        cwd = "~/.config/nvim",
        hidden = true,
    })
end

M.git_branches = function()
    require("telescope.builtin").git_branches({
        attach_mappings = function(_, map)
            map("i", "<c-d>", actions.git_delete_branch)
            map("n", "<c-d>", actions.git_delete_branch)
            return true
        end,
    })
end

M.spellcheck = function()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local make_entry = require("telescope.make_entry")

    local locations = vim.fn.getqflist()

    if vim.tbl_isempty(locations) then
        return
    end

    pickers
        .new({
            prompt_title = "SpellCheck",
            finder = finders.new_table({
                results = locations,
                entry_maker = make_entry.gen_from_quickfix(),
            }),
        })
        :find()
end

M.find_files_under = function()
    require("telescope.builtin").find_files({
        prompt_title = "< Find files under... >",
        cwd = vim.fn.expand("%:p:h"),
    })
end

M.mappings = function()
    -- TODO: When selected, open the file where the mapping is defined
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local sorters = require("telescope.sorters")
    local make_entry = require("telescope.make_entry")

    local map_output = vim.api.nvim_exec("map", true)

    local locations = {}
    for line in map_output:gmatch("([^\n]*)\n?") do
        table.insert(locations, line)
    end

    if vim.tbl_isempty(locations) then
        return
    end

    pickers
        .new({
            prompt_title = "Mappings",
            finder = finders.new_table({
                results = locations,
            }),
            sorter = sorters.get_generic_fuzzy_sorter(),
        })
        :find()
end

M.grep_word_under_cursor = function()
    opts = opts or {}

    local register = vim.fn.expand("<cword>")

    opts.path_display = { "absolute" }
    opts.word_match = "-w"
    opts.search = register

    require("telescope.builtin").grep_string(opts)
end

M.buffers = function()
    require("telescope.builtin").buffers({
        attach_mappings = function(_, map)
            map("i", "<c-d>", actions.delete_buffer)
            return true
        end,
    })
end

local function set_background(content)
    local os = vim.inspect(vim.fn.system("uname"))
    os = string.gsub(os, "\\n", "")
    os = string.gsub(os, '"', "")
    local cmd = ""
    if os == "Linux" then
        cmd = "feh --bg-fill " .. content
    else
        cmd = "changeBackground " .. content
    end
    vim.fn.system(cmd)
end

local function delete_background(prompt_bufnr, map)
    local function rm_background()
        local content = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
        local file = content.cwd .. "/" .. content.value
        local cmd = "rm -f " .. file
        -- TODO: Add confirmation before deleting the file
        vim.fn.system(cmd)
    end

    map("i", "<C-d>", function()
        rm_background()
    end)
end

local function select_background(prompt_bufnr, map)
    local function set_the_background(close)
        local content = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
        set_background(content.cwd .. "/" .. content.value)
        if close then
            require("telescope.actions").close(prompt_bufnr)
        end
    end

    map("i", "<C-p>", function()
        set_the_background()
    end)

    map("i", "<CR>", function()
        set_the_background(true)
    end)
end

local function image_selector(prompt, cwd)
    return function()
        require("telescope.builtin").find_files({
            prompt_title = prompt,
            cwd = cwd,
            previewer = false,
            attach_mappings = function(prompt_bufnr, map)
                select_background(prompt_bufnr, map)
                delete_background(prompt_bufnr, map)

                -- Please continue mapping (attaching additional key maps):
                -- Ctrl+n/p to move up and down the list.
                return true
            end,
        })
    end
end

M.background_selector = image_selector("< Background Selector > ", "~/Desktop/git/backgrounds")

local diff_commit = function(prompt_bufnr, mode)
    local selection = action_state.get_selected_entry()
    require("telescope.actions").close(prompt_bufnr)
    -- vim.cmd(string.format('call VimDiffView("%s")', selection.value))
    vim.cmd(string.format("DiffviewOpen %s", selection.value))
end

M.git_commits = function(opts)
    local output =
        utils.get_os_command_output({ "git", "log", "--pretty=format:%h/%s/%an", "--abbrev-commit", "--", "." })

    local results = {}
    local parse_line = function(line)
        local fields = vim.split(line, "/", true)
        local entry = {
            hash = fields[1],
            subject = fields[2],
            author = fields[3],
        }
        local index = 1
        if entry.hash ~= "*" then
            index = #results + 1
        end
        -- P(results)
        table.insert(results, index, entry)
    end

    for _, line in ipairs(output) do
        parse_line(line)
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 10 },
            { width = 80 },
            { width = 20 },
        },
    })

    local make_display = function(entry)
        return displayer({
            { entry.hash },
            { entry.subject, "TelescopeResultsIdentifier" },
            { entry.author },
        })
    end

    local entry_maker = function(entry)
        entry.value = entry.hash
        entry.ordinal = entry.subject .. entry.author .. entry.hash
        entry.display = make_display
        return entry
    end

    opts.entry_maker = entry_maker

    pickers
        .new(opts, {
            prompt_title = "Custom Git Commits",
            finder = finders.new_table({
                results = results,
                entry_maker = function(entry)
                    entry.value = entry.hash
                    entry.ordinal = entry.subject .. entry.author .. entry.hash
                    entry.display = make_display
                    return entry
                end,
            }),
            previewer = previewers.git_commit_message.new(opts),
            sorter = conf.file_sorter(opts),
            attach_mappings = function(_, map)
                actions.select_default:replace(actions.git_checkout)
                map("i", "<c-d>", diff_commit)
                map("n", "<c-d>", diff_commit)
                return true
            end,
        })
        :find()
end

M.git_file_commits = function(opts)
    opts = opts or {}
    local current_file = vim.fn.expand('%')
    if current_file == '' then
        vim.notify('No file is currently open', vim.log.levels.ERROR)
        return
    end

    -- Get the git root directory
    local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    if not git_root then
        vim.notify('Not in a git repository', vim.log.levels.ERROR)
        return
    end

    local output = utils.get_os_command_output({
        "git",
        "log",
        "--pretty=format:%h/%s/%an/%ad",
        "--date=format:%Y-%m-%d %H:%M",
        "--abbrev-commit",
        "--",
        current_file
    })

    if vim.tbl_isempty(output) then
        vim.notify('No git history found for this file', vim.log.levels.WARN)
        return
    end

    local results = {}
    local parse_line = function(line)
        local fields = vim.split(line, "/", true)
        local entry = {
            hash = fields[1],
            subject = fields[2],
            author = fields[3],
            date = fields[4]
        }
        table.insert(results, entry)
    end

    for _, line in ipairs(output) do
        parse_line(line)
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 10 },  -- hash
            { width = 50 },  -- subject
            { width = 20 },  -- author
            { width = 20 },  -- date
        },
    })

    local make_display = function(entry)
        return displayer({
            { entry.hash, "TelescopeResultsIdentifier" },
            { entry.subject },
            { entry.author, "TelescopeResultsComment" },
            { entry.date, "TelescopeResultsComment" },
        })
    end

    pickers.new(opts, {
        prompt_title = "Git File History: " .. current_file,
        finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
                entry.value = entry.hash
                entry.ordinal = entry.subject .. entry.author .. entry.date .. entry.hash
                entry.display = make_display
                return entry
            end,
        }),
        previewer = previewers.git_commit_message.new(opts),
        sorter = conf.file_sorter(opts),
        attach_mappings = function(_, map)
            actions.select_default:replace(actions.git_checkout)
            map("i", "<c-d>", diff_commit)
            map("n", "<c-d>", diff_commit)
            return true
        end,
    }):find()
end

-- GitHub API helpers
local function get_github_token()
    local token = os.getenv("NVIM_GITHUB_TOKEN")
    if not token then
        vim.notify("Please set NVIM_GITHUB_TOKEN environment variable", vim.log.levels.ERROR)
        return nil
    end
    return token
end

local function github_api_request(endpoint)
    local token = get_github_token()
    if not token then
        return nil
    end

    local curl_cmd = string.format(
        'curl -s -H "Authorization: token %s" -H "Accept: application/vnd.github.v3+json" "https://api.github.com%s"',
        token, endpoint
    )
    P(curl_cmd)

    local handle = io.popen(curl_cmd)
    local response = handle:read("*a")
    handle:close()

    return vim.fn.json_decode(response)
end

local function get_team_members()
    local response = github_api_request("/orgs/Shopify/teams/foundations-analytics-data-team/members")
    if not response then
        return {}
    end

    local members = {}
    for _, member in ipairs(response) do
        table.insert(members, {
            login = member.login,
            name = member.name or member.login,
            avatar_url = member.avatar_url,
            html_url = member.html_url
        })
    end

    return members
end

local function get_current_repo()
    -- Get the current repository name from git remote
    local remote_url = vim.fn.system("git config --get remote.origin.url 2>/dev/null"):gsub("%s+", "")
    if remote_url == "" then
        return nil
    end

    -- Extract repo name from various URL formats
    local repo_name = remote_url:match("github%.com[:/]Shopify/([^/%.]+)")
    return repo_name
end

local function get_user_prs(username)
    local current_repo = get_current_repo()
    if not current_repo then
        vim.notify("Not in a git repository or no GitHub remote found", vim.log.levels.ERROR)
        return {}
    end

    -- Search for open PRs only (including drafts) in the current repository
    local repo_query = string.format("repo:Shopify/%s", current_repo)
    local all_prs_response = github_api_request(string.format("/search/issues?q=author:%s+is:pr+state:open+%s", username, repo_query))

    local prs = {}
    local seen_numbers = {}

    if all_prs_response and all_prs_response.items then
        for _, pr in ipairs(all_prs_response.items) do
            -- Avoid duplicates by checking if we've seen this PR number before
            if not seen_numbers[pr.number] then
                seen_numbers[pr.number] = true

                -- Determine state based on PR properties (all results are open, but may be draft)
                local state = pr.draft and "draft" or "open"

                table.insert(prs, {
                    number = pr.number,
                    title = pr.title,
                    state = state,
                    html_url = pr.html_url,
                    created_at = pr.created_at,
                    updated_at = pr.updated_at,
                    repo_name = current_repo,
                    labels = pr.labels or {}
                })
            end
        end
    end

    -- Sort by updated_at (most recent first)
    table.sort(prs, function(a, b) return a.updated_at > b.updated_at end)

    return prs
end

local function open_pr_with_diffview(pr_number)
    local git_clean_and_reset = function()
        -- First, close any existing DiffView
        vim.cmd("DiffviewClose")

        -- Reset any working directory changes
        vim.fn.system("git reset --hard HEAD")

        -- Clean untracked files
        vim.fn.system("git clean -fd")

        -- Checkout main/master to ensure clean state
        local main_branch = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"):gsub("%s+", "")
        if main_branch == "" then
            main_branch = "main"  -- fallback to main
        end
        vim.fn.system("git checkout " .. main_branch)

        -- Pull latest changes
        vim.fn.system("git pull origin " .. main_branch)

        -- Delete the PR branch if it exists
        vim.fn.system("git branch -D pr-" .. pr_number .. " 2>/dev/null")
    end

    local fetch_pr = function(pr_num)
        local cmd = "git fetch origin pull/" .. pr_num .. "/head:pr-" .. pr_num
        vim.fn.system(cmd)
        local cmd2 = "git checkout pr-" .. pr_num
        vim.fn.system(cmd2)
    end

    local open_with_diffview = function()
        -- Get the main branch name
        local main_branch = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"):gsub("%s+", "")
        if main_branch == "" then
            main_branch = "main"  -- fallback to main
        end

        -- Find the merge base (parent commit where PR branch was created)
        local merge_base = vim.fn.system("git merge-base HEAD origin/" .. main_branch):gsub("%s+", "")

        -- Open DiffView with commit range from merge base to HEAD (only PR changes)
        local cmd = "DiffviewOpen " .. merge_base .. "..HEAD"
        vim.cmd(cmd)
    end

    git_clean_and_reset()
    fetch_pr(pr_number)
    open_with_diffview()
end

M.team_members_picker = function()
    local members = get_team_members()

    if vim.tbl_isempty(members) then
        vim.notify("No team members found or API error", vim.log.levels.ERROR)
        return
    end
    
    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 20 },  -- login
            { width = 30 },  -- name
        },
    })
    
    local make_display = function(entry)
        return displayer({
            { entry.login, "TelescopeResultsIdentifier" },
            { entry.name, "TelescopeResultsComment" },
        })
    end
    
    pickers.new({}, {
        prompt_title = "Team Members - Core Analytics Data Team",
        finder = finders.new_table({
            results = members,
            entry_maker = function(entry)
                entry.value = entry.login
                entry.ordinal = entry.login .. " " .. entry.name
                entry.display = make_display
                return entry
            end,
        }),
        sorter = conf.file_sorter({}),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                M.user_prs_picker(selection.value)
            end)
            return true
        end,
    }):find()
end

M.user_prs_picker = function(username)
    local prs = get_user_prs(username)
    local current_repo = get_current_repo()
    
    if vim.tbl_isempty(prs) then
        vim.notify("No PRs found for " .. username .. " in " .. (current_repo or "current repo"), vim.log.levels.WARN)
        return
    end
    
    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 6 },   -- number
            { width = 8 },   -- state
            { width = 50 },  -- title
            { width = 20 },  -- repo
            { width = 12 },  -- updated
        },
    })
    
    local make_display = function(entry)
        local state_color = entry.state == "open" and "TelescopeResultsIdentifier" or "TelescopeResultsComment"
        local date = entry.updated_at:match("(%d%d%d%d%-%d%d%-%d%d)")
        
        return displayer({
            { "#" .. entry.number, "TelescopeResultsNumber" },
            { entry.state, state_color },
            { entry.title },
            { entry.repo_name, "TelescopeResultsComment" },
            { date, "TelescopeResultsComment" },
        })
    end
    
    pickers.new({}, {
        prompt_title = "PRs by " .. username .. " in " .. (current_repo or "current repo"),
        finder = finders.new_table({
            results = prs,
            entry_maker = function(entry)
                entry.value = entry.number
                entry.ordinal = entry.title .. " " .. entry.repo_name .. " " .. entry.number
                entry.display = make_display
                return entry
            end,
        }),
        sorter = conf.file_sorter({}),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                open_pr_with_diffview(selection.value)
            end)
            
            -- Add shortcut to open PR with diffview (similar to git_file_commits)
            map("i", "<c-d>", function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                open_pr_with_diffview(selection.value)
            end)
            
            map("n", "<c-d>", function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                open_pr_with_diffview(selection.value)
            end)
            
            -- Add shortcut to open PR in browser
            map("i", "<c-o>", function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local pr_data = nil
                for _, pr in ipairs(prs) do
                    if pr.number == selection.value then
                        pr_data = pr
                        break
                    end
                end
                if pr_data then
                    local cmd = "silent ! open -a 'Google Chrome' -n --args " .. pr_data.html_url
                    vim.cmd(cmd)
                end
            end)
            
            return true
        end,
    }):find()
end

-- Create a command to start the team PR workflow
M.team_pr_workflow = function()
    M.team_members_picker()
end

-- Alternative: Manual username input for PR workflow
M.manual_user_pr_workflow = function()
    local Input = require("nui.input")
    local event = require("nui.utils.autocmd").event

    local input = Input({
        position = "50%",
        size = {
            width = 30,
        },
        border = {
            style = "single",
            text = {
                top = "GitHub Username",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
        },
    }, {
        prompt = "> ",
        default_value = "",
        on_close = function()
            print("Input Closed!")
        end,
        on_submit = function(value)
            if value and value ~= "" then
                M.user_prs_picker(value)
            end
        end,
    })

    -- mount/open the component
    input:mount()

    -- unmount component when cursor leaves buffer
    input:on(event.BufLeave, function()
        input:unmount()
    end)
end

-- Function to get current branch name
local function get_current_branch()
    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+", "")
    if vim.v.shell_error ~= 0 or branch == "" then
        return nil
    end
    return branch
end

-- Function to find PR for current branch
local function get_pr_for_current_branch()
    local current_repo = get_current_repo()
    local current_branch = get_current_branch()
    
    if not current_repo then
        vim.notify("Not in a git repository or no GitHub remote found", vim.log.levels.ERROR)
        return nil
    end
    
    if not current_branch then
        vim.notify("Could not determine current branch", vim.log.levels.ERROR)
        return nil
    end
    
    if current_branch == "main" or current_branch == "master" then
        vim.notify("Currently on main/master branch - no PR expected", vim.log.levels.WARN)
        return nil
    end
    
    -- First, try to search for PRs with the current branch as head
    local repo_query = string.format("repo:Shopify/%s", current_repo)
    local branch_query = string.format("head:%s", current_branch)
    local search_query = string.format("is:pr+state:open+%s+%s", repo_query, branch_query)
    
    local response = github_api_request(string.format("/search/issues?q=%s", search_query))
    
    -- If we found a PR, return it
    if response and response.items and #response.items > 0 then
        local pr = response.items[1]
        return {
            number = pr.number,
            title = pr.title,
            html_url = pr.html_url,
            state = pr.draft and "draft" or "open",
            branch = current_branch,
            repo = current_repo
        }
    end
    
    -- If no PR found and branch looks like "pr-XXXX", try to get PR by number
    local pr_number = current_branch:match("^pr%-(%d+)$")
    if pr_number then
        local pr_response = github_api_request(string.format("/repos/Shopify/%s/pulls/%s", current_repo, pr_number))
        if pr_response and pr_response.number then
            return {
                number = pr_response.number,
                title = pr_response.title,
                html_url = pr_response.html_url,
                state = pr_response.draft and "draft" or "open",
                branch = current_branch,
                repo = current_repo
            }
        end
    end
    
    vim.notify("No open PR found for branch: " .. current_branch, vim.log.levels.WARN)
    return nil
end

-- Function to open PR in browser
M.open_current_branch_pr = function()
    local pr = get_pr_for_current_branch()
    
    if not pr then
        return
    end
    
    vim.notify(string.format("Opening PR #%d: %s", pr.number, pr.title), vim.log.levels.INFO)
    
    local cmd = "silent ! open -a 'Google Chrome' -n --args " .. pr.html_url
    vim.cmd(cmd)
end

return M
