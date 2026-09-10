local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function command_key(command)
    return table.concat(command, "\0")
end

local function ok(stdout)
    return { code = 0, stdout = stdout or "", stderr = "" }
end

local function failed(stderr)
    return { code = 1, stdout = "", stderr = stderr or "failed" }
end

local function route(routes, command, result)
    routes[command_key(command)] = result
end

local function fake_dependencies(routes)
    return {
        run = function(command)
            local result = routes[command_key(command)]
            check(result ~= nil, "unexpected command: " .. table.concat(command, " "))
            return result
        end,
        decode = vim.json.decode,
    }
end

local BASE = "c06847f7fe935a3f20ceb149386a288991aa8178"
local HEAD = "66b5340e73119a5f9e89458bbbe6b5e382cb123a"
local GITHUB_BASE = "958654feb2941b5c6c0d748cdebe0bd8c7692edf"

local gitstream_remote = table.concat({
    "origin\thttps://gitstream.shopify.io/shop/world.git (fetch)",
    "origin\thttps://gitstream.shopify.io/shop/world.git (push)",
    "github\thttps://github.com/shop/world.git (fetch)",
}, "\n")

local function test_gitstream_precedes_github()
    local routes = {}
    route(routes, { "git", "remote", "-v" }, ok(gitstream_remote))
    route(routes, { "git", "rev-parse", "--abbrev-ref", "HEAD" }, ok("miguelmora/sandworm-sweep-run\n"))
    route(routes, {
        "gs", "pr", "list", "--head", "miguelmora/sandworm-sweep-run", "--json", "--limit", "1",
    }, ok(vim.json.encode({ { baseSha = BASE, headSha = HEAD } })))
    route(routes, { "git", "merge-base", "HEAD", BASE }, ok(BASE .. "\n"))

    local actual = require("mmp.pr_base").get_merge_base(fake_dependencies(routes))
    check(actual == BASE, "Gitstream base was not selected")
end

local function test_github_repository()
    local routes = {}
    route(routes, { "git", "remote", "-v" }, ok("origin\thttps://github.com/shop/world.git (fetch)\n"))
    route(routes, { "gh", "pr", "view", "--json", "baseRefOid", "-q", ".baseRefOid" }, ok(GITHUB_BASE .. "\n"))
    route(routes, { "git", "merge-base", "HEAD", GITHUB_BASE }, ok(GITHUB_BASE .. "\n"))

    local actual = require("mmp.pr_base").get_merge_base(fake_dependencies(routes))
    check(actual == GITHUB_BASE, "GitHub base was not selected")
end

local function test_github_fallback_after_gitstream_miss()
    local routes = {}
    route(routes, { "git", "remote", "-v" }, ok(gitstream_remote))
    route(routes, { "git", "rev-parse", "--abbrev-ref", "HEAD" }, ok("miguelmora/sandworm-sweep-run\n"))
    route(routes, {
        "gs", "pr", "list", "--head", "miguelmora/sandworm-sweep-run", "--json", "--limit", "1",
    }, ok("[]"))
    route(routes, { "gh", "pr", "view", "--json", "baseRefOid", "-q", ".baseRefOid" }, ok(GITHUB_BASE .. "\n"))
    route(routes, { "git", "merge-base", "HEAD", GITHUB_BASE }, ok(GITHUB_BASE .. "\n"))

    local actual = require("mmp.pr_base").get_merge_base(fake_dependencies(routes))
    check(actual == GITHUB_BASE, "GitHub fallback was not selected")
end

local function test_malformed_gitstream_response()
    local routes = {}
    route(routes, { "git", "remote", "-v" }, ok("origin\thttps://gitstream.shopify.io/shop/world.git (fetch)\n"))
    route(routes, { "git", "rev-parse", "--abbrev-ref", "HEAD" }, ok("topic\n"))
    route(routes, { "gs", "pr", "list", "--head", "topic", "--json", "--limit", "1" }, ok("not json"))

    local actual = require("mmp.pr_base").get_merge_base(fake_dependencies(routes))
    check(actual == nil, "malformed Gitstream metadata should return nil")
end

local function test_fetch_remote_host_detection()
    local routes = {}
    local remotes = table.concat({
        "origin\thttps://gitstream.shopify.io/shop/world.git (push)",
        "origin\thttps://github.com/shop/gitstream.shopify.io.git (fetch)",
    }, "\n")
    route(routes, { "git", "remote", "-v" }, ok(remotes))
    route(routes, { "gh", "pr", "view", "--json", "baseRefOid", "-q", ".baseRefOid" }, failed())

    local actual = require("mmp.pr_base").get_merge_base(fake_dependencies(routes))
    check(actual == nil, "push-only and path substring matches should not select Gitstream")
end

local function test_default_runner_handles_missing_provider_cli()
    local previous_system = vim.system
    local previous_pr_base = package.loaded["mmp.pr_base"]
    package.loaded["mmp.pr_base"] = nil
    vim.system = function(command)
        if command[1] == "gs" then
            error("ENOENT: no such file or directory: gs")
        end

        local responses = {
            [command_key({ "git", "remote", "-v" })] = "origin\thttps://gitstream.shopify.io/shop/world.git (fetch)\n",
            [command_key({ "git", "rev-parse", "--abbrev-ref", "HEAD" })] = "topic\n",
        }
        local stdout = responses[command_key(command)]
        check(stdout ~= nil, "unexpected command: " .. table.concat(command, " "))
        return { wait = function() return ok(stdout) end }
    end

    local succeeded, result = xpcall(function()
        return require("mmp.pr_base").get_merge_base()
    end, debug.traceback)

    vim.system = previous_system
    package.loaded["mmp.pr_base"] = previous_pr_base
    if not succeeded then
        error(result, 0)
    end
    check(result == nil, "missing provider CLI should return nil")
end

local function with_pr_base(result, system, callback)
    local previous_base = package.loaded["mmp.pr_base"]
    local previous_gitsigns = package.loaded["mmp.pr_gitsigns"]
    local previous_system = vim.fn.system
    local previous_systemlist = vim.fn.systemlist
    package.loaded["mmp.pr_base"] = {
        get_merge_base = function()
            return type(result) == "function" and result() or result
        end,
    }
    package.loaded["mmp.pr_gitsigns"] = nil
    vim.fn.system = system
    vim.fn.systemlist = function(command)
        return vim.split(system(command), "\n", { plain = true, trimempty = true })
    end

    local succeeded, message = xpcall(function()
        callback(require("mmp.pr_gitsigns"))
    end, debug.traceback)

    vim.fn.system = previous_system
    vim.fn.systemlist = previous_systemlist
    package.loaded["mmp.pr_base"] = previous_base
    package.loaded["mmp.pr_gitsigns"] = previous_gitsigns
    if not succeeded then
        error(message, 0)
    end
end

local function detached_system(command)
    local responses = {
        ["git rev-parse --abbrev-ref HEAD 2>/dev/null"] = "HEAD\n",
        ["git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"] = "main\n",
        ["git rev-parse HEAD 2>/dev/null"] = HEAD .. "\n",
    }
    local response = responses[command]
    check(response ~= nil, "unexpected detached HEAD command: " .. tostring(command))
    return response
end

local function with_gitsigns(callback)
    local previous_gitsigns = package.loaded["gitsigns"]
    local changed_base
    package.loaded["gitsigns"] = {
        change_base = function(base, global)
            changed_base = { base = base, global = global }
        end,
    }

    local succeeded, message = xpcall(callback, debug.traceback)
    package.loaded["gitsigns"] = previous_gitsigns
    if not succeeded then
        error(message, 0)
    end
    return changed_base
end

local function with_immediate_defer(callback)
    local previous_defer_fn = vim.defer_fn
    vim.defer_fn = function(deferred_callback)
        deferred_callback()
    end

    local succeeded, message = xpcall(callback, debug.traceback)
    vim.defer_fn = previous_defer_fn
    if not succeeded then
        error(message, 0)
    end
end

local function test_pr_gitsigns_prefers_provider_base()
    with_pr_base(BASE, function(command)
        error("unexpected trunk command: " .. tostring(command))
    end, function(pr_gitsigns)
        check(pr_gitsigns.get_merge_base() == BASE, "PR base was not returned directly")
    end)
end

local function test_pr_gitsigns_retains_trunk_fallback()
    local child = HEAD
    local responses = {
        ["git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"] = "main\n",
        ["git cherry origin/main HEAD 2>/dev/null"] = "+ " .. child .. "\n",
        ["git rev-parse " .. child .. "^ 2>/dev/null"] = BASE .. "\n",
    }
    with_pr_base(nil, function(command)
        local response = responses[command]
        check(response ~= nil, "unexpected trunk command: " .. tostring(command))
        return response
    end, function(pr_gitsigns)
        check(pr_gitsigns.get_merge_base() == BASE, "trunk fallback did not return the unique commit parent")
    end)
end

local function test_pr_gitsigns_enables_detached_pr_head()
    local resolutions = 0
    local changed_base = with_gitsigns(function()
        with_pr_base(function()
            resolutions = resolutions + 1
            return BASE
        end, detached_system, function(pr_gitsigns)
            pr_gitsigns.enable_pr_diff_mode()
        end)
    end)

    check(changed_base ~= nil, "detached PR HEAD should enable PR diff mode")
    check(changed_base.base == BASE, "detached PR HEAD should compare against the PR base")
    check(changed_base.global == true, "detached PR HEAD should change the base globally")
    check(resolutions == 1, "detached PR HEAD should resolve its base once")
end

local function test_pr_gitsigns_setup_enables_current_detached_pr()
    local resolutions = 0
    local changed_base = with_gitsigns(function()
        with_immediate_defer(function()
            with_pr_base(function()
                resolutions = resolutions + 1
                return BASE
            end, detached_system, function(pr_gitsigns)
                pr_gitsigns.setup()
            end)
        end)
    end)

    check(changed_base ~= nil, "setup should enable PR diff mode for the current detached PR")
    check(changed_base.base == BASE, "setup should compare the current detached PR against its base")
    check(changed_base.global == true, "setup should change the base globally")
    check(resolutions == 1, "setup should resolve a detached PR base once")
end

local function test_pr_gitsigns_ignores_detached_trunk_head()
    local changed_base = with_gitsigns(function()
        with_pr_base(HEAD, detached_system, function(pr_gitsigns)
            pr_gitsigns.enable_pr_diff_mode()
        end)
    end)

    check(changed_base == nil, "detached trunk HEAD should keep the default Gitsigns base")
end

local function test_detached_head_resolution_is_cached_per_commit()
    local current_head = HEAD
    local resolutions = 0
    local function system(command)
        if command == "git rev-parse HEAD 2>/dev/null" then
            return current_head .. "\n"
        end
        return detached_system(command)
    end

    with_pr_base(function()
        resolutions = resolutions + 1
        return resolutions == 1 and HEAD or BASE
    end, system, function(pr_gitsigns)
        check(not pr_gitsigns.get_status().is_pr_branch, "detached trunk HEAD should not be a PR")
        check(not pr_gitsigns.get_status().is_pr_branch, "detached trunk HEAD status should stay stable")
        current_head = GITHUB_BASE
        check(pr_gitsigns.get_status().is_pr_branch, "a new detached PR HEAD should refresh its base")
    end)

    check(resolutions == 2, "detached HEAD classification should resolve once per commit")
end

local function test_telescope_uses_shared_base()
    local source = table.concat(vim.fn.readfile("lua/mmp/telescope.lua"), "\n")
    check(not source:find("local function get_pr_merge_base", 1, true), "Telescope still defines a PR-base resolver")
    check(not source:find("gh pr view --json baseRefOid", 1, true), "Telescope still invokes gh directly")

    local needle = 'local merge_base = require("mmp.pr_gitsigns").get_merge_base()'
    local count = 0
    local offset = 1
    while true do
        local start = source:find(needle, offset, true)
        if not start then
            break
        end
        count = count + 1
        offset = start + #needle
    end
    check(count == 2, "expected both Telescope PR pickers to use the shared base")
    check(
        source:find(
            "Could not determine PR or branch base (need gs/gh PR context or an origin remote)",
            1,
            true
        ) ~= nil,
        "branch changed-files error should describe provider and origin fallbacks"
    )
end

local function run()
    test_gitstream_precedes_github()
    test_github_repository()
    test_github_fallback_after_gitstream_miss()
    test_malformed_gitstream_response()
    test_fetch_remote_host_detection()
    test_default_runner_handles_missing_provider_cli()
    test_pr_gitsigns_prefers_provider_base()
    test_pr_gitsigns_retains_trunk_fallback()
    test_pr_gitsigns_enables_detached_pr_head()
    test_pr_gitsigns_setup_enables_current_detached_pr()
    test_pr_gitsigns_ignores_detached_trunk_head()
    test_detached_head_resolution_is_cached_per_commit()
    test_telescope_uses_shared_base()
end

local success, message = xpcall(run, debug.traceback)
if not success then
    io.stderr:write("pr_base_spec failure:\n" .. tostring(message) .. "\n")
    vim.cmd("cquit 1")
end

print("PR base resolver: ok")
vim.cmd("qa!")
