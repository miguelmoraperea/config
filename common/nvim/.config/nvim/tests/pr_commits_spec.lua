local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function run_command(command, cwd)
    local result = vim.system(command, { cwd = cwd, text = true }):wait()
    if result.code ~= 0 then
        error(string.format("command failed (%s): %s", table.concat(command, " "), result.stderr), 2)
    end
    return vim.trim(result.stdout)
end

local function git(repo, ...)
    local command = { "git", "-C", repo }
    vim.list_extend(command, { ... })
    return run_command(command)
end

local function write_file(path, content)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile({ content }, path)
end

local function commit_file(repo, relative_path, content, subject)
    write_file(repo .. "/" .. relative_path, content)
    git(repo, "add", "--", relative_path)
    git(repo, "commit", "-m", subject)
    return git(repo, "rev-parse", "HEAD")
end

local captured = {}
local selected_entry
local provider = {
    main_branch = "main",
    merge_base = nil,
    merge_base_calls = 0,
}

local function execute(command)
    local result = vim.system(command, { text = true }):wait()
    if result.code ~= 0 then
        return {}
    end
    return vim.split(result.stdout, "\n", { plain = true, trimempty = true })
end

package.preload["telescope"] = function()
    return {
        setup = function() end,
        load_extension = function() end,
    }
end
package.preload["telescope.sorters"] = function()
    return {
        get_fzy_sorter = function() return {} end,
        get_generic_fuzzy_sorter = function() return {} end,
    }
end
package.preload["telescope.make_entry"] = function()
    return {}
end
package.preload["telescope.actions"] = function()
    return {
        select_default = {
            replace = function(_, callback)
                captured.select_default = callback
            end,
        },
        close = function() end,
    }
end
package.preload["telescope.actions.state"] = function()
    return {
        get_selected_entry = function()
            return selected_entry
        end,
    }
end
package.preload["telescope.utils"] = function()
    return {
        get_os_command_output = function(command)
            captured.sync_command = command
            return execute(command)
        end,
    }
end
package.preload["telescope.pickers.entry_display"] = function()
    return {
        create = function()
            return function(columns)
                return columns
            end
        end,
    }
end
package.preload["telescope.pickers"] = function()
    return {
        new = function(options, specification)
            captured.picker_options = options
            captured.picker = specification
            return {
                find = function()
                    captured.started = true
                end,
            }
        end,
    }
end
package.preload["telescope.finders"] = function()
    local function make_entries(results, entry_maker)
        local entries = {}
        for _, result in ipairs(results) do
            local entry = entry_maker and entry_maker(result) or result
            if entry then
                table.insert(entries, entry)
            end
        end
        return entries
    end

    return {
        new_table = function(specification)
            captured.finder_kind = "table"
            captured.finder_specification = specification
            return {
                entries = make_entries(specification.results, specification.entry_maker),
            }
        end,
        new_oneshot_job = function(command, options)
            captured.finder_kind = "oneshot"
            captured.async_command = command
            captured.async_options = options
            return {
                entries = make_entries(execute(command), options.entry_maker),
            }
        end,
    }
end
package.preload["telescope.config"] = function()
    return {
        values = {
            file_sorter = function()
                return {}
            end,
        },
    }
end
package.preload["telescope.previewers"] = function()
    return {
        vim_buffer_cat = { new = function() end },
        vim_buffer_vimgrep = { new = function() end },
        vim_buffer_qflist = { new = function() end },
        buffer_previewer_maker = function() end,
        new_buffer_previewer = function(specification)
            captured.previewer = specification
            return specification
        end,
    }
end
package.loaded["mmp.pr_gitsigns"] = {
    get_main_branch = function()
        return provider.main_branch
    end,
    get_merge_base = function()
        provider.merge_base_calls = provider.merge_base_calls + 1
        return provider.merge_base
    end,
}

local notifications = {}
local original_notify = vim.notify
vim.notify = function(message, level)
    table.insert(notifications, { message = message, level = level })
end

local function reset_capture()
    captured = {}
    notifications = {}
    provider.merge_base_calls = 0
    provider.main_branch = "main"
    provider.merge_base = nil
end

local function contains(list, value)
    return vim.tbl_contains(list, value)
end

local function entry_subjects()
    local subjects = {}
    for _, entry in ipairs(captured.picker.finder.entries) do
        table.insert(subjects, entry.subject)
    end
    return subjects
end

local function setup_repo()
    local repo = vim.fn.tempname() .. " repo"
    vim.fn.mkdir(repo, "p")
    git(repo, "init", "-b", "main")
    git(repo, "config", "user.email", "test@example.com")
    git(repo, "config", "user.name", "Test User")

    write_file(repo .. "/zone one/zone.nix", "zone one")
    commit_file(repo, "zone one/nested/file.txt", "initial", "zone initial")
    write_file(repo .. "/zone two/zone.nix", "zone two")
    commit_file(repo, "zone two/file.txt", "sibling", "sibling change")
    commit_file(repo, "docs/readme.txt", "docs", "docs change")
    git(repo, "config", "user.name", "Author / Name")
    commit_file(repo, "zone one/nested/file.txt", "updated", "ordered async I/O")
    return repo
end

local function test_trunk_uses_async_zone_history(module, repo)
    reset_capture()
    vim.cmd.cd(vim.fn.fnameescape(repo .. "/zone one/nested"))

    module.pr_commits({})

    check(provider.merge_base_calls == 0, "trunk called PR base resolution")
    check(captured.finder_kind == "oneshot", "trunk history did not use an asynchronous finder")
    check(captured.started, "trunk picker did not start")
    check(captured.picker.prompt_title:find("Recent Zone Commits", 1, true), "trunk title does not identify zone history")
    check(contains(captured.async_command, "--max-count=100"), "trunk history is not limited to 100 commits")
    local separator_index = vim.fn.index(captured.async_command, "--") + 1
    check(separator_index > 0, "trunk command omitted the pathspec separator")
    check(captured.async_command[separator_index + 1] == "zone one", "nested cwd did not resolve to the zone root")

    local subjects = entry_subjects()
    check(#subjects == 2, "zone history included commits outside the zone")
    check(subjects[1] == "ordered async I/O", "subject containing a slash was parsed incorrectly")
    check(captured.picker.finder.entries[1].author == "Author / Name", "author containing a slash was parsed incorrectly")
    check(not contains(subjects, "sibling change"), "zone history included a sibling zone")
    check(not contains(subjects, "docs change"), "zone history broadened to the repository")
end

local function test_async_history_output_ends_with_newline(module, repo)
    reset_capture()
    vim.cmd.cd(vim.fn.fnameescape(repo .. "/zone one/nested"))

    module.pr_commits({})

    local result = vim.system(captured.async_command, { text = true }):wait()
    check(result.code == 0, "async git command failed")
    check(result.stdout:sub(-1) == "\n", "async git output did not end with a newline")
end

local function test_trunk_falls_back_to_cwd(module, repo)
    reset_capture()
    vim.cmd.cd(vim.fn.fnameescape(repo .. "/docs"))

    module.pr_commits({})

    check(captured.picker.prompt_title:find("Recent Directory Commits", 1, true), "cwd fallback title is unclear")
    local separator_index = vim.fn.index(captured.async_command, "--") + 1
    check(captured.async_command[separator_index + 1] == "docs", "cwd fallback used the wrong pathspec")
    local subjects = entry_subjects()
    check(#subjects == 1 and subjects[1] == "docs change", "cwd fallback did not restrict history to cwd")
end

local function test_configured_default_branch_is_trunk(module, repo)
    reset_capture()
    git(repo, "checkout", "-b", "configured-trunk")
    provider.main_branch = "configured-trunk"
    vim.cmd.cd(vim.fn.fnameescape(repo .. "/zone one"))

    module.pr_commits({})

    check(provider.merge_base_calls == 0, "configured origin default branch called PR base resolution")
    check(captured.finder_kind == "oneshot", "configured origin default branch did not use history")
    git(repo, "checkout", "main")
end

local function test_feature_branch_keeps_pr_range(module, repo)
    reset_capture()
    provider.merge_base = git(repo, "rev-parse", "main")
    git(repo, "checkout", "-b", "feature")
    commit_file(repo, "zone two/feature.txt", "feature", "feature sibling")
    commit_file(repo, "docs/feature.txt", "feature", "feature docs")
    vim.cmd.cd(vim.fn.fnameescape(repo .. "/zone one/nested"))

    module.pr_commits({})

    check(provider.merge_base_calls == 1, "feature branch did not resolve its PR base")
    check(captured.finder_kind == "table", "feature branch behavior changed to the history finder")
    check(captured.picker.prompt_title:find("PR Commits", 1, true), "feature branch lost its PR title")
    local subjects = entry_subjects()
    check(#subjects == 2, "feature branch commits were filtered by the current zone")
    check(contains(subjects, "feature sibling") and contains(subjects, "feature docs"), "feature branch lost commits")
    check(not contains(captured.sync_command, "--max-count=100"), "feature branch was incorrectly limited as history")
end

local function test_empty_feature_branch_stays_empty(module, repo)
    git(repo, "checkout", "main")
    git(repo, "checkout", "-b", "empty-feature")
    reset_capture()
    provider.merge_base = git(repo, "rev-parse", "main")
    vim.cmd.cd(vim.fn.fnameescape(repo .. "/zone one"))

    module.pr_commits({})

    check(provider.merge_base_calls == 1, "empty feature branch did not resolve its PR base")
    check(not captured.started, "empty feature branch silently fell back to history")
    check(#notifications == 1 and notifications[1].message:find("No commits in this branch", 1, true), "empty branch message changed")
end

local function test_non_git_cwd_stops_before_provider(module)
    reset_capture()
    local directory = vim.fn.tempname() .. " non git"
    vim.fn.mkdir(directory, "p")
    vim.cmd.cd(vim.fn.fnameescape(directory))

    module.pr_commits({})

    check(provider.merge_base_calls == 0, "non-git cwd called PR base resolution")
    check(not captured.started, "non-git cwd opened a picker")
    check(#notifications == 1 and notifications[1].message == "Not in a git repository", "non-git error was not reported")
end

local function run()
    local original_cwd = vim.fn.getcwd()
    local repo = setup_repo()
    local module = require("mmp.telescope")

    local succeeded, message = xpcall(function()
        test_trunk_uses_async_zone_history(module, repo)
        test_async_history_output_ends_with_newline(module, repo)
        test_trunk_falls_back_to_cwd(module, repo)
        test_configured_default_branch_is_trunk(module, repo)
        test_feature_branch_keeps_pr_range(module, repo)
        test_empty_feature_branch_stays_empty(module, repo)
        test_non_git_cwd_stops_before_provider(module)
    end, debug.traceback)

    vim.cmd.cd(vim.fn.fnameescape(original_cwd))
    vim.fn.delete(repo, "rf")
    vim.notify = original_notify
    if not succeeded then
        error(message, 0)
    end
end

local success, message = xpcall(run, debug.traceback)
if not success then
    io.stderr:write("pr_commits_spec failure:\n" .. tostring(message) .. "\n")
    vim.cmd("cquit 1")
end

print("PR commits picker: ok")
vim.cmd("qa!")
