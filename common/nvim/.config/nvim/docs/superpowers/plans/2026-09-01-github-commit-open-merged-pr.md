# GitHub Commit Open Merged PR Implementation Plan

> For agentic workers: REQUIRED: load the `subagent-driven-development`
> Superpowers skill with `superpowers_skill` (if subagents are available),
> or load `executing-plans` with the same tool to implement this plan.

**Goal:** Make `:GithubCommitOpen` resolve a blamed commit remotely and open its contextual merged GitHub or Meteorite pull request, with a Telescope picker when several merged reviews are valid.

**Architecture:** Add one coordinator module that discovers provider-specific repository identities, performs asynchronous remote CLI calls, validates exact PR membership, and decides whether to open, pick, fall back, or report an error. Add a separate Telescope adapter so selection UI remains isolated from remote lookup logic and can be replaced by a test fake. Keep the existing user command as a thin adapter from `<cword>` into the coordinator.

**Tech Stack:** Neovim Lua, `vim.system`, Telescope, `gh`, `gs`, and headless Neovim Lua specs.

## File structure

- Create `common/nvim/.config/nvim/lua/mmp/github_commit.lua`: remote repository discovery, SHA canonicalization, GitHub and Gitstream candidate validation, result sorting, and navigation decision.
- Create `common/nvim/.config/nvim/lua/mmp/github_commit_picker.lua`: Telescope rendering and selection for multiple valid merged PRs.
- Create `common/nvim/.config/nvim/lua/mmp/github_commit_command.lua`: independently loadable user-command registration.
- Modify `common/nvim/.config/nvim/lua/mmp/init.lua`: delegate `:GithubCommitOpen` setup to the command adapter.
- Create `common/nvim/.config/nvim/tests/github_commit_spec.lua`: deterministic coordinator coverage through injected command, browser, picker, and notification adapters.
- Create `common/nvim/.config/nvim/tests/github_commit_picker_spec.lua`: focused Telescope adapter behavior with stubbed Telescope modules.
- Create `common/nvim/.config/nvim/tests/github_commit_command_spec.lua`: test the command adapter under `-u NONE` without loading the full configuration.

All commands below run from:

```sh
cd /Users/miguel/Desktop/git/miguelmora--github-commit-open-merged-pr/common/nvim/.config/nvim
```

### Task 1: Remote merged-PR resolver

**Files:**
- Create: `common/nvim/.config/nvim/lua/mmp/github_commit.lua`
- Create: `common/nvim/.config/nvim/tests/github_commit_spec.lua`

- [ ] **Step 1: Write the failing coordinator spec**

Create `tests/github_commit_spec.lua`:

```lua
local function main()
local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function command_key(args)
    return table.concat(args, "\31")
end

local function add_response(responses, args, response)
    responses[command_key(args)] = response
end

local function ok(stdout)
    return { code = 0, stdout = stdout or "", stderr = "" }
end

local function failed(stderr)
    return { code = 1, stdout = "", stderr = stderr or "failed" }
end

local function json(value)
    return vim.json.encode(value)
end

local function fake_dependencies(responses)
    local state = {
        commands = {},
        opened = {},
        notifications = {},
        picked = nil,
        choose = nil,
    }

    local dependencies = {
        run = function(args, callback)
            table.insert(state.commands, args)
            local response = responses[command_key(args)]
            check(response ~= nil, "unexpected command: " .. table.concat(args, " "))
            callback(response)
        end,
        open = function(url)
            table.insert(state.opened, url)
        end,
        notify = function(message, level)
            table.insert(state.notifications, { message = message, level = level })
        end,
        pick = function(candidates, on_choice)
            state.picked = candidates
            state.choose = on_choice
        end,
    }

    return dependencies, state
end

local function run_case(name, body)
    local success, err = xpcall(body, debug.traceback)
    if not success then
        error(name .. ":\n" .. tostring(err), 0)
    end
end

local function check_failed_without_open(state, label)
    check(#state.opened == 0, label .. " incorrectly opened a URL")
    check(#state.notifications == 1, label .. " should notify exactly once")
end

local module = dofile("lua/mmp/github_commit.lua")
local short_sha = "5ef9def9bb4c72"
local full_sha = "5ef9def9bb4c7212edfa90db368b255db4d686d0"
local dual_remotes = table.concat({
    "origin\tgit@gitstream.shopify.io:shop/world.git (fetch)",
    "origin\tgit@gitstream.shopify.io:shop/world.git (push)",
    "github\tgit@github.com:shop/world.git (fetch)",
    "github\tgit@github.com:shop/world.git (push)",
}, "\n") .. "\n"
local gitstream_remote = table.concat({
    "origin\tgit@gitstream.shopify.io:shop/world.git (fetch)",
    "origin\tgit@gitstream.shopify.io:shop/world.git (push)",
}, "\n") .. "\n"

run_case("dual remotes select the exact GitHub PR", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(dual_remotes))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok(json({
        {
            number = 1006544,
            title = "Sweep manifest freezes plan",
            state = "merged",
            closedAt = "2026-08-21T15:26:45Z",
            url = "https://github.com/shop/world/pull/1006544",
        },
    })))
    add_response(
        responses,
        { "gh", "api", "repos/shop/world/pulls/1006544" },
        ok(json({
            number = 1006544,
            title = "Sweep manifest freezes plan",
            merged = true,
            merged_at = "2026-08-21T15:26:45Z",
            merge_commit_sha = "57aa821f4e4e62774b0574c60099c4869c17b706",
            html_url = "https://github.com/shop/world/pull/1006544",
        }))
    )
    add_response(responses, {
        "gh", "api", "--paginate", "--slurp",
        "repos/shop/world/pulls/1006544/commits?per_page=100",
    }, ok(json({ { { sha = full_sha } } })))
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2019897,
            title = "Open replacement",
            merged = false,
            merged_at = vim.NIL,
            merge_commit_sha = vim.NIL,
        },
        {
            number = 2014193,
            title = "Unrelated merged snapshot",
            merged = true,
            merged_at = "2026-08-27T00:24:24Z",
            merge_commit_sha = "49bce6e236d4ca6e7a5dd4cd1100841ddeaef03f",
        },
    })))
    add_response(responses, {
        "gs", "api", "repos/shop/world/pulls/2014193/commits?per_page=100", "--paginate",
    }, ok(json({ { sha = "862bf0c10b76e077ea94ee52b26204399fa039c7" } })))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)

    check(#state.notifications == 0, "unexpected notification")
    check(state.picked == nil, "one valid PR should not open the picker")
    check(#state.opened == 1, "expected one browser URL")
    check(
        state.opened[1]
            == "https://github.com/shop/world/pull/1006544/commits/" .. full_sha,
        "opened the wrong GitHub commit URL: " .. tostring(state.opened[1])
    )
end)

run_case("a GitHub-only remote canonicalizes remotely", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(
        "github\tgit@github.com:shop/world.git (fetch)\n"
    ))
    add_response(
        responses,
        { "gh", "api", "repos/shop/world/commits/" .. short_sha, "--jq", ".sha" },
        ok(full_sha .. "\n")
    )
    add_response(responses, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok("[]"))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check(
        state.opened[1] == "https://github.com/shop/world/commit/" .. full_sha,
        "GitHub-only lookup did not use the canonical SHA"
    )
end)

run_case("an exact merged Meteorite PR opens directly", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2014193,
            title = "Exact Meteorite PR",
            merged = true,
            merged_at = "2026-08-27T00:24:24Z",
            merge_commit_sha = "49bce6e236d4ca6e7a5dd4cd1100841ddeaef03f",
        },
    })))
    add_response(responses, {
        "gs", "api", "repos/shop/world/pulls/2014193/commits?per_page=100", "--paginate",
    }, ok(json({ { sha = full_sha } })))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)

    check(#state.opened == 1, "expected one Meteorite URL")
    check(
        state.opened[1]
            == "https://meteorite.shopify.io/repos/shop/world/pulls/2014193/commits/"
                .. full_sha,
        "opened the wrong Meteorite commit URL"
    )
end)

run_case("a merge commit SHA is valid without listing PR commits", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2014193,
            title = "Merge commit match",
            merged = true,
            merged_at = "2026-08-27T00:24:24Z",
            merge_commit_sha = full_sha,
        },
    })))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check(#state.opened == 1, "merge commit candidate was not opened")
end)

run_case("multiple exact merged PRs use the sorted picker", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2020002,
            title = "Later merge",
            merged = true,
            merged_at = "2026-08-29T10:00:00Z",
            merge_commit_sha = "2222222222222222222222222222222222222222",
        },
        {
            number = 2020001,
            title = "Earlier merge",
            merged = true,
            merged_at = "2026-08-28T10:00:00Z",
            merge_commit_sha = "1111111111111111111111111111111111111111",
        },
    })))
    for _, number in ipairs({ 2020002, 2020001 }) do
        add_response(responses, {
            "gs", "api",
            "repos/shop/world/pulls/" .. number .. "/commits?per_page=100",
            "--paginate",
        }, ok(json({ { sha = full_sha } })))
    end

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)

    check(#state.opened == 0, "picker should decide what to open")
    check(state.picked ~= nil and #state.picked == 2, "expected two picker entries")
    check(state.picked[1].number == 2020001, "picker was not sorted oldest first")
    state.choose(state.picked[2])
    check(
        state.opened[1]:find("/pulls/2020002/commits/", 1, true) ~= nil,
        "picker selection opened the wrong PR"
    )
end)

run_case("cancelling a multi-PR picker opens nothing", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2020001,
            title = "One",
            merged = true,
            merged_at = "2026-08-28T10:00:00Z",
            merge_commit_sha = full_sha,
        },
        {
            number = 2020002,
            title = "Two",
            merged = true,
            merged_at = "2026-08-29T10:00:00Z",
            merge_commit_sha = full_sha,
        },
    })))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check(state.picked ~= nil, "expected picker")
    state.choose(nil)
    check(#state.opened == 0, "cancelling the picker opened a URL")
end)

run_case("confirmed absence opens the GitHub commit fallback", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(dual_remotes))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok("[]"))
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok("[]"))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check(
        state.opened[1] == "https://github.com/shop/world/commit/" .. full_sha,
        "confirmed absence did not use the GitHub commit fallback"
    )
end)

run_case("lookup failure does not masquerade as absence", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(dual_remotes))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, failed("HTTP 502"))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check(#state.opened == 0, "API failure incorrectly opened the fallback")
    check(#state.notifications == 1, "API failure should notify once")
    check(
        state.notifications[1].message:find("GitHub PR search", 1, true) ~= nil,
        "notification did not identify the failing lookup"
    )
end)

run_case("GitHub PR detail failure is terminal", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(
        "github\tgit@github.com:shop/world.git (fetch)\n"
    ))
    add_response(
        responses,
        { "gh", "api", "repos/shop/world/commits/" .. short_sha, "--jq", ".sha" },
        ok(full_sha .. "\n")
    )
    add_response(responses, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok(json({ { number = 1006544 } })))
    add_response(
        responses,
        { "gh", "api", "repos/shop/world/pulls/1006544" },
        failed("detail unavailable")
    )

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check_failed_without_open(state, "GitHub PR detail failure")
end)

run_case("GitHub commit-list failure is terminal", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(
        "github\tgit@github.com:shop/world.git (fetch)\n"
    ))
    add_response(
        responses,
        { "gh", "api", "repos/shop/world/commits/" .. short_sha, "--jq", ".sha" },
        ok(full_sha .. "\n")
    )
    add_response(responses, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok(json({ { number = 1006544 } })))
    add_response(
        responses,
        { "gh", "api", "repos/shop/world/pulls/1006544" },
        ok(json({
            number = 1006544,
            title = "Candidate",
            merged = true,
            merged_at = "2026-08-21T15:26:45Z",
            merge_commit_sha = "57aa821f4e4e62774b0574c60099c4869c17b706",
            html_url = "https://github.com/shop/world/pull/1006544",
        }))
    )
    add_response(responses, {
        "gh", "api", "--paginate", "--slurp",
        "repos/shop/world/pulls/1006544/commits?per_page=100",
    }, failed("commit list unavailable"))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check_failed_without_open(state, "GitHub commit-list failure")
end)

run_case("Meteorite association failure is terminal", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, failed("association unavailable"))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check_failed_without_open(state, "Meteorite association failure")
end)

run_case("Meteorite commit-list failure is terminal", function()
    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        responses,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(responses, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2014193,
            title = "Candidate",
            merged = true,
            merged_at = "2026-08-27T00:24:24Z",
            merge_commit_sha = "49bce6e236d4ca6e7a5dd4cd1100841ddeaef03f",
        },
    })))
    add_response(responses, {
        "gs", "api", "repos/shop/world/pulls/2014193/commits?per_page=100", "--paginate",
    }, failed("commit list unavailable"))

    local dependencies, state = fake_dependencies(responses)
    module.open(short_sha, dependencies)
    check_failed_without_open(state, "Meteorite commit-list failure")
end)

run_case("malformed candidate and validation responses are terminal", function()
    local malformed_search = {}
    add_response(malformed_search, { "git", "remote", "-v" }, ok(
        "github\tgit@github.com:shop/world.git (fetch)\n"
    ))
    add_response(
        malformed_search,
        { "gh", "api", "repos/shop/world/commits/" .. short_sha, "--jq", ".sha" },
        ok(full_sha .. "\n")
    )
    add_response(malformed_search, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok(json({ { number = "not-a-number" } })))

    local dependencies, search_state = fake_dependencies(malformed_search)
    module.open(short_sha, dependencies)
    check_failed_without_open(search_state, "malformed GitHub candidate")

    local malformed_commits = {}
    add_response(malformed_commits, { "git", "remote", "-v" }, ok(
        "github\tgit@github.com:shop/world.git (fetch)\n"
    ))
    add_response(
        malformed_commits,
        { "gh", "api", "repos/shop/world/commits/" .. short_sha, "--jq", ".sha" },
        ok(full_sha .. "\n")
    )
    add_response(malformed_commits, {
        "gh", "search", "prs", full_sha,
        "--repo", "shop/world", "--merged", "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, ok(json({ { number = 1006544 } })))
    add_response(
        malformed_commits,
        { "gh", "api", "repos/shop/world/pulls/1006544" },
        ok(json({
            number = 1006544,
            title = "Candidate",
            merged = true,
            merged_at = "2026-08-21T15:26:45Z",
            merge_commit_sha = "57aa821f4e4e62774b0574c60099c4869c17b706",
        }))
    )
    add_response(malformed_commits, {
        "gh", "api", "--paginate", "--slurp",
        "repos/shop/world/pulls/1006544/commits?per_page=100",
    }, ok(json({ { { sha = "invalid" } } })))

    local commit_dependencies, commits_state = fake_dependencies(malformed_commits)
    module.open(short_sha, commit_dependencies)
    check_failed_without_open(commits_state, "malformed GitHub commit list")

    local malformed_meteorite = {}
    add_response(malformed_meteorite, { "git", "remote", "-v" }, ok(gitstream_remote))
    add_response(
        malformed_meteorite,
        { "gs", "api", "repos/shop/world/commits/" .. short_sha },
        ok(json({ sha = full_sha }))
    )
    add_response(malformed_meteorite, {
        "gs", "api",
        "repos/shop/world/commits/" .. full_sha .. "/pulls?per_page=100",
        "--paginate",
    }, ok(json({
        {
            number = 2014193,
            title = "Malformed merge metadata",
            merged = true,
            merged_at = vim.NIL,
            merge_commit_sha = "invalid",
        },
    })))

    local meteorite_dependencies, meteorite_state = fake_dependencies(malformed_meteorite)
    module.open(short_sha, meteorite_dependencies)
    check_failed_without_open(meteorite_state, "malformed Meteorite candidate")
end)

run_case("invalid hashes and unsupported remotes fail locally", function()
    local dependencies, invalid_state = fake_dependencies({})
    module.open("not-a-hash", dependencies)
    check(#invalid_state.commands == 0, "invalid hash should not run commands")
    check(#invalid_state.notifications == 1, "invalid hash should notify")

    local responses = {}
    add_response(responses, { "git", "remote", "-v" }, ok(
        "origin\tgit@gitlab.example.com:shop/world.git (fetch)\n"
    ))
    local remote_dependencies, remote_state = fake_dependencies(responses)
    module.open(short_sha, remote_dependencies)
    check(#remote_state.opened == 0, "unsupported remote should not open")
    check(#remote_state.notifications == 1, "unsupported remote should notify")
end)

print("github commit resolver: ok")
end

local success, err = xpcall(main, debug.traceback)
if not success then
    print(err)
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
```

- [ ] **Step 2: Run the coordinator spec and verify it fails**

Run:

```sh
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_spec.lua"
```

Expected: FAIL because `lua/mmp/github_commit.lua` does not exist.

- [ ] **Step 3: Implement the remote coordinator**

Create `lua/mmp/github_commit.lua`:

```lua
local M = {}

local provider_hosts = {
    github = "github.com",
    gitstream = "gitstream.shopify.io",
}

local remote_name_priority = {
    github = { github = 1, upstream = 2, origin = 3 },
    gitstream = { origin = 1 },
}

local provider_rank = { Meteorite = 1, GitHub = 2 }

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function default_run(args, callback)
    vim.system(args, { text = true }, function(result)
        vim.schedule(function()
            callback(result)
        end)
    end)
end

local function default_open(url)
    vim.fn.jobstart({ "open", "-a", "Google Chrome", "-n", "--args", url }, { detach = true })
end

local function dependencies(overrides)
    overrides = overrides or {}
    return {
        run = overrides.run or default_run,
        open = overrides.open or default_open,
        notify = overrides.notify or vim.notify,
        pick = overrides.pick or function(candidates, on_choice)
            require("mmp.github_commit_picker").select(candidates, on_choice)
        end,
    }
end

local function fail(operation, deps, message)
    if operation.terminal then
        return
    end
    operation.terminal = true
    deps.notify(message, vim.log.levels.ERROR)
end

local function run_text(operation, deps, args, label, on_success)
    if operation.terminal then
        return
    end
    deps.run(args, function(result)
        if operation.terminal then
            return
        end
        if type(result) ~= "table" or type(result.code) ~= "number" then
            fail(operation, deps, label .. ": invalid command result")
            return
        end
        if result.code ~= 0 then
            local detail = type(result.stderr) == "string" and trim(result.stderr) or ""
            fail(operation, deps, label .. (detail ~= "" and ": " .. detail or " failed"))
            return
        end
        if result.stdout ~= nil and type(result.stdout) ~= "string" then
            fail(operation, deps, label .. ": invalid command output")
            return
        end
        on_success(result.stdout or "")
    end)
end

local function run_json(operation, deps, args, label, on_success)
    run_text(operation, deps, args, label, function(output)
        local decoded, value = pcall(vim.json.decode, output)
        if not decoded then
            fail(operation, deps, label .. ": invalid JSON response")
            return
        end
        on_success(value)
    end)
end

local function parse_remote_url(url)
    local host, path = url:match("^git@([^:]+):(.+)$")
    if not host then
        host, path = url:match("^ssh://[^@]+@([^/]+)/(.+)$")
    end
    if not host then
        host, path = url:match("^https?://([^/]+)/(.+)$")
    end
    if not host or not path then
        return nil
    end

    path = path:gsub("^/", ""):gsub("/+$", ""):gsub("%.git$", "")
    local owner, repo = path:match("^([^/]+)/([^/]+)$")
    if not owner or not repo then
        return nil
    end

    return { host = host:lower(), owner = owner, repo = repo }
end

local function select_identity(remotes, provider)
    local candidates = {}
    for _, remote in ipairs(remotes) do
        local parsed = parse_remote_url(remote.url)
        if parsed and parsed.host == provider_hosts[provider] then
            parsed.name = remote.name
            parsed.score = remote_name_priority[provider][remote.name] or 10
            table.insert(candidates, parsed)
        end
    end

    table.sort(candidates, function(left, right)
        if left.score == right.score then
            return left.name < right.name
        end
        return left.score < right.score
    end)
    return candidates[1]
end

local function repository_context(output)
    local remotes = {}
    for line in output:gmatch("[^\n]+") do
        local name, url, direction = line:match("^(%S+)%s+(%S+)%s+%((%a+)%)$")
        if name and url and direction == "fetch" then
            table.insert(remotes, { name = name, url = url })
        end
    end

    return {
        github = select_identity(remotes, "github"),
        gitstream = select_identity(remotes, "gitstream"),
    }
end

local function repo_name(identity)
    return identity.owner .. "/" .. identity.repo
end

local function plausible_hash(value)
    return type(value) == "string"
        and #value >= 7
        and #value <= 40
        and value:match("^[0-9a-fA-F]+$") ~= nil
end

local function canonical_sha(value)
    if not plausible_hash(value) or #value ~= 40 then
        return nil
    end
    return value:lower()
end

local function valid_number(value)
    local number = tonumber(value)
    if not number or number <= 0 or number % 1 ~= 0 then
        return nil
    end
    return number
end

local function validate_merged_detail(detail, expected_number, label)
    if type(detail) ~= "table" or vim.islist(detail) then
        return nil, label .. ": expected a pull request object"
    end

    local number = valid_number(detail.number)
    if not number or (expected_number and number ~= expected_number) then
        return nil, label .. ": invalid pull request number"
    end
    if type(detail.merged) ~= "boolean" then
        return nil, label .. ": invalid merged state"
    end
    if not detail.merged then
        return { number = number, merged = false }
    end
    if type(detail.title) ~= "string" then
        return nil, label .. ": invalid title"
    end
    if type(detail.merged_at) ~= "string" or detail.merged_at == "" then
        return nil, label .. ": invalid merged timestamp"
    end

    local merge_commit_sha
    if detail.merge_commit_sha ~= nil and detail.merge_commit_sha ~= vim.NIL then
        merge_commit_sha = canonical_sha(detail.merge_commit_sha)
        if not merge_commit_sha then
            return nil, label .. ": invalid merge commit SHA"
        end
    end
    if detail.html_url ~= nil
        and detail.html_url ~= vim.NIL
        and type(detail.html_url) ~= "string"
    then
        return nil, label .. ": invalid pull request URL"
    end

    return {
        number = number,
        title = detail.title,
        merged = true,
        merged_at = detail.merged_at,
        merge_commit_sha = merge_commit_sha,
        html_url = detail.html_url ~= vim.NIL and detail.html_url or nil,
    }
end

local function canonical_hash(operation, context, raw_hash, deps, on_success)
    if context.gitstream then
        local endpoint = "repos/" .. repo_name(context.gitstream) .. "/commits/" .. raw_hash
        run_json(operation, deps, { "gs", "api", endpoint }, "Commit lookup", function(commit)
            local sha = type(commit) == "table" and canonical_sha(commit.sha) or nil
            if not sha then
                fail(operation, deps, "Commit lookup returned an invalid SHA")
                return
            end
            on_success(sha)
        end)
        return
    end

    local endpoint = "repos/" .. repo_name(context.github) .. "/commits/" .. raw_hash
    run_text(operation, deps, { "gh", "api", endpoint, "--jq", ".sha" }, "Commit lookup", function(output)
        local sha = canonical_sha(trim(output))
        if not sha then
            fail(operation, deps, "Commit lookup returned an invalid SHA")
            return
        end
        on_success(sha)
    end)
end

local function github_candidate(identity, detail, sha)
    local number = detail.number
    return {
        provider = "GitHub",
        number = number,
        title = detail.title,
        merged_at = detail.merged_at,
        url = detail.html_url
            or ("https://github.com/" .. repo_name(identity) .. "/pull/" .. number),
        commit_url = "https://github.com/"
            .. repo_name(identity)
            .. "/pull/"
            .. number
            .. "/commits/"
            .. sha,
    }
end

local function meteorite_candidate(identity, detail, sha)
    local number = detail.number
    local url = "https://meteorite.shopify.io/repos/"
        .. repo_name(identity)
        .. "/pulls/"
        .. number
    return {
        provider = "Meteorite",
        number = number,
        title = detail.title,
        merged_at = detail.merged_at,
        url = url,
        commit_url = url .. "/commits/" .. sha,
    }
end

local function github_pages_contain(pages, sha)
    if type(pages) ~= "table" or not vim.islist(pages) then
        return nil, "GitHub PR commits lookup: expected paginated arrays"
    end
    for _, page in ipairs(pages) do
        if type(page) ~= "table" or not vim.islist(page) then
            return nil, "GitHub PR commits lookup: expected a commit array"
        end
        for _, commit in ipairs(page) do
            local commit_sha = type(commit) == "table" and canonical_sha(commit.sha) or nil
            if not commit_sha then
                return nil, "GitHub PR commits lookup: invalid commit SHA"
            end
            if commit_sha == sha then
                return true
            end
        end
    end
    return false
end

local function gitstream_commits_contain(commits, sha)
    if type(commits) ~= "table" or not vim.islist(commits) then
        return nil, "Meteorite PR commits lookup: expected a commit array"
    end
    for _, commit in ipairs(commits) do
        local commit_sha = type(commit) == "table" and canonical_sha(commit.sha) or nil
        if not commit_sha then
            return nil, "Meteorite PR commits lookup: invalid commit SHA"
        end
        if commit_sha == sha then
            return true
        end
    end
    return false
end

local function validate_github_candidates(operation, context, sha, candidates, deps, on_success)
    if type(candidates) ~= "table" or not vim.islist(candidates) then
        fail(operation, deps, "GitHub PR search: expected a candidate array")
        return
    end

    local valid = {}
    local function visit(index)
        if operation.terminal then
            return
        end
        local candidate = candidates[index]
        if not candidate then
            on_success(valid)
            return
        end

        local number = type(candidate) == "table" and valid_number(candidate.number) or nil
        if not number then
            fail(operation, deps, "GitHub PR search: invalid pull request number")
            return
        end

        local endpoint = "repos/" .. repo_name(context.github) .. "/pulls/" .. number
        run_json(operation, deps, { "gh", "api", endpoint }, "GitHub PR lookup", function(detail)
            local normalized, detail_error = validate_merged_detail(
                detail,
                number,
                "GitHub PR lookup"
            )
            if not normalized then
                fail(operation, deps, detail_error)
                return
            end
            if not normalized.merged then
                visit(index + 1)
                return
            end
            if normalized.merge_commit_sha == sha then
                table.insert(valid, github_candidate(context.github, normalized, sha))
                visit(index + 1)
                return
            end

            local commits_endpoint = endpoint .. "/commits?per_page=100"
            run_json(operation, deps, {
                "gh", "api", "--paginate", "--slurp", commits_endpoint,
            }, "GitHub PR commits lookup", function(pages)
                local contains, commits_error = github_pages_contain(pages, sha)
                if contains == nil then
                    fail(operation, deps, commits_error)
                    return
                end
                if contains then
                    table.insert(valid, github_candidate(context.github, normalized, sha))
                end
                visit(index + 1)
            end)
        end)
    end

    visit(1)
end

local function collect_github(operation, context, sha, deps, on_success)
    if not context.github then
        on_success({})
        return
    end

    run_json(operation, deps, {
        "gh", "search", "prs", sha,
        "--repo", repo_name(context.github),
        "--merged",
        "--limit", "1000",
        "--json", "number,title,state,closedAt,url",
    }, "GitHub PR search", function(candidates)
        validate_github_candidates(operation, context, sha, candidates, deps, on_success)
    end)
end

local function validate_meteorite_candidates(operation, context, sha, candidates, deps, on_success)
    if type(candidates) ~= "table" or not vim.islist(candidates) then
        fail(operation, deps, "Meteorite PR search: expected a candidate array")
        return
    end

    local valid = {}
    local function visit(index)
        if operation.terminal then
            return
        end
        local candidate = candidates[index]
        if not candidate then
            on_success(valid)
            return
        end

        local normalized, detail_error = validate_merged_detail(
            candidate,
            nil,
            "Meteorite PR search"
        )
        if not normalized then
            fail(operation, deps, detail_error)
            return
        end
        if not normalized.merged then
            visit(index + 1)
            return
        end
        if normalized.merge_commit_sha == sha then
            table.insert(valid, meteorite_candidate(context.gitstream, normalized, sha))
            visit(index + 1)
            return
        end

        local endpoint = "repos/"
            .. repo_name(context.gitstream)
            .. "/pulls/"
            .. normalized.number
            .. "/commits?per_page=100"
        run_json(operation, deps, {
            "gs", "api", endpoint, "--paginate",
        }, "Meteorite PR commits lookup", function(commits)
            local contains, commits_error = gitstream_commits_contain(commits, sha)
            if contains == nil then
                fail(operation, deps, commits_error)
                return
            end
            if contains then
                table.insert(valid, meteorite_candidate(context.gitstream, normalized, sha))
            end
            visit(index + 1)
        end)
    end

    visit(1)
end

local function collect_meteorite(operation, context, sha, deps, on_success)
    if not context.gitstream then
        on_success({})
        return
    end

    local endpoint = "repos/"
        .. repo_name(context.gitstream)
        .. "/commits/"
        .. sha
        .. "/pulls?per_page=100"
    run_json(operation, deps, {
        "gs", "api", endpoint, "--paginate",
    }, "Meteorite PR search", function(candidates)
        validate_meteorite_candidates(operation, context, sha, candidates, deps, on_success)
    end)
end

local function sorted_unique(candidates)
    local unique = {}
    local seen = {}
    for _, candidate in ipairs(candidates) do
        if not seen[candidate.url] then
            seen[candidate.url] = true
            table.insert(unique, candidate)
        end
    end

    table.sort(unique, function(left, right)
        local left_time = left.merged_at or "9999"
        local right_time = right.merged_at or "9999"
        if left_time == right_time then
            local left_rank = provider_rank[left.provider] or 99
            local right_rank = provider_rank[right.provider] or 99
            if left_rank == right_rank then
                return left.number < right.number
            end
            return left_rank < right_rank
        end
        return left_time < right_time
    end)
    return unique
end

local function present(operation, context, sha, candidates, deps)
    if operation.terminal then
        return
    end
    operation.terminal = true

    local valid = sorted_unique(candidates)
    if #valid == 1 then
        deps.open(valid[1].commit_url)
        return
    end
    if #valid > 1 then
        deps.pick(valid, function(selection)
            if selection then
                deps.open(selection.commit_url)
            end
        end)
        return
    end

    local fallback_identity = context.github or context.gitstream
    deps.open("https://github.com/" .. repo_name(fallback_identity) .. "/commit/" .. sha)
end

function M.open(raw_hash, overrides)
    local deps = dependencies(overrides)
    local operation = { terminal = false }
    if not plausible_hash(raw_hash) then
        fail(operation, deps, "No valid commit hash under cursor")
        return
    end

    run_text(operation, deps, { "git", "remote", "-v" }, "Git remote lookup", function(output)
        local context = repository_context(output)
        if not context.github and not context.gitstream then
            fail(operation, deps, "No GitHub or Gitstream remote found")
            return
        end

        canonical_hash(operation, context, raw_hash, deps, function(sha)
            collect_github(operation, context, sha, deps, function(github_candidates)
                collect_meteorite(operation, context, sha, deps, function(meteorite_candidates)
                    vim.list_extend(github_candidates, meteorite_candidates)
                    present(operation, context, sha, github_candidates, deps)
                end)
            end)
        end)
    end)
end

return M
```

- [ ] **Step 4: Run the coordinator spec and verify it passes**

Run:

```sh
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_spec.lua"
```

Expected: PASS with `github commit resolver: ok`.

- [ ] **Step 5: Check formatting and commit Task 1**

Run:

```sh
STYLUA="$HOME/.local/share/nvim/mason/bin/stylua"
"$STYLUA" lua/mmp/github_commit.lua tests/github_commit_spec.lua
"$STYLUA" --check lua/mmp/github_commit.lua tests/github_commit_spec.lua
git diff --check
```

Expected: both commands exit 0.

Commit only Task 1 files:

```sh
G=/opt/homebrew/bin/git
$G add lua/mmp/github_commit.lua tests/github_commit_spec.lua
$G commit -m "Resolve merged PRs for commits"
```

### Task 2: Telescope picker and command wiring

**Depends on:** Task 1

**Files:**
- Create: `common/nvim/.config/nvim/lua/mmp/github_commit_picker.lua`
- Create: `common/nvim/.config/nvim/lua/mmp/github_commit_command.lua`
- Create: `common/nvim/.config/nvim/tests/github_commit_picker_spec.lua`
- Create: `common/nvim/.config/nvim/tests/github_commit_command_spec.lua`
- Modify: `common/nvim/.config/nvim/lua/mmp/init.lua:702-715`

- [ ] **Step 1: Write the failing Telescope picker spec**

Create `tests/github_commit_picker_spec.lua`:

```lua
local function main()
local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local captured
local found = false
local selected
local closed
local replacement
local empty_sorter = {}

package.loaded["telescope.pickers"] = {
    new = function(_, spec)
        captured = spec
        return {
            find = function()
                found = true
            end,
        }
    end,
}
package.loaded["telescope.finders"] = {
    new_table = function(spec)
        return spec
    end,
}
package.loaded["telescope.sorters"] = {
    empty = function()
        return empty_sorter
    end,
}
package.loaded["telescope.pickers.entry_display"] = {
    create = function()
        return function(columns)
            return columns
        end
    end,
}
package.loaded["telescope.actions"] = {
    select_default = {
        replace = function(_, callback)
            replacement = callback
        end,
    },
    close = function(prompt_bufnr)
        closed = prompt_bufnr
    end,
}
package.loaded["telescope.actions.state"] = {
    get_selected_entry = function()
        return selected
    end,
}

local candidates = {
    {
        provider = "GitHub",
        number = 1006544,
        title = "Sweep manifest freezes plan",
        merged_at = "2026-08-21T15:26:45Z",
        commit_url = "https://github.example/first",
    },
    {
        provider = "Meteorite",
        number = 2014193,
        title = "Later review",
        merged_at = "2026-08-27T00:24:24Z",
        commit_url = "https://meteorite.example/second",
    },
}

local chosen
local picker = dofile("lua/mmp/github_commit_picker.lua")
picker.select(candidates, function(candidate)
    chosen = candidate
end)

check(found, "Telescope picker did not start")
check(captured.prompt_title == "Merged pull requests", "wrong prompt title")
check(captured.finder.results == candidates, "picker did not preserve candidate order")
check(captured.finder.results[1] == candidates[1], "oldest candidate is not displayed first")
check(captured.sorter == empty_sorter, "picker sorter may reorder candidates")
check(captured.default_selection_index == 1, "oldest candidate is not initially selected")

local first = captured.finder.entry_maker(candidates[1])
check(first.value == candidates[1], "entry did not preserve the candidate")
check(
    first.ordinal:find("Sweep manifest freezes plan", 1, true) ~= nil,
    "entry title is not searchable"
)
check(
    first.ordinal:find("1006544", 1, true) ~= nil,
    "entry number is not searchable"
)

check(captured.attach_mappings(41, function() end), "attach_mappings must retain mappings")
selected = { value = candidates[2] }
replacement(41)
check(closed == 41, "selection did not close Telescope")
check(chosen == candidates[2], "selection returned the wrong candidate")

print("github commit picker: ok")
end

local success, err = xpcall(main, debug.traceback)
if not success then
    print(err)
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
```

- [ ] **Step 2: Write the failing user-command spec**

Create `tests/github_commit_command_spec.lua`:

```lua
local function main()
local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local captured
package.loaded["mmp.github_commit"] = {
    open = function(hash)
        captured = hash
    end,
}

local hash = "5ef9def9bb4c72"
local command = dofile("lua/mmp/github_commit_command.lua")
command.setup(function()
    return hash
end)

check(vim.fn.exists(":GithubCommitOpen") == 2, ":GithubCommitOpen does not exist")
vim.api.nvim_cmd({ cmd = "GithubCommitOpen" }, {})
check(captured == hash, "command did not pass the cursor hash to mmp.github_commit")

local init_source = table.concat(vim.fn.readfile("lua/mmp/init.lua"), "\n")
check(
    init_source:find(
        'require("mmp.github_commit_command").setup(get_commit_under_cursor)',
        1,
        true
    ) ~= nil,
    "mmp.init does not delegate GithubCommitOpen registration to the command adapter"
)

print("github commit command: ok")
end

local success, err = xpcall(main, debug.traceback)
if not success then
    print(err)
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
```

- [ ] **Step 3: Run both new specs and verify they fail**

Run:

```sh
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_picker_spec.lua"
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_command_spec.lua"
```

Expected:

- Picker spec exits nonzero because `lua/mmp/github_commit_picker.lua` does not exist.
- Command spec exits nonzero because `lua/mmp/github_commit_command.lua` does not exist.
- Neither spec loads `init.lua`, starts a plugin manager, makes a remote request, or opens a browser.

- [ ] **Step 4: Implement the Telescope picker**

Create `lua/mmp/github_commit_picker.lua`:

```lua
local M = {}

function M.select(candidates, on_choice)
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entry_display = require("telescope.pickers.entry_display")
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")
    local sorters = require("telescope.sorters")

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 11 },
            { width = 10 },
            { width = 12 },
            { remaining = true },
        },
    })

    local function make_display(entry)
        local candidate = entry.value
        return displayer({
            { candidate.provider, "TelescopeResultsIdentifier" },
            { "#" .. candidate.number, "TelescopeResultsNumber" },
            { candidate.merged_at:sub(1, 10), "TelescopeResultsComment" },
            { candidate.title },
        })
    end

    pickers.new({}, {
        prompt_title = "Merged pull requests",
        finder = finders.new_table({
            results = candidates,
            entry_maker = function(candidate)
                return {
                    value = candidate,
                    ordinal = table.concat({
                        candidate.provider,
                        tostring(candidate.number),
                        candidate.merged_at or "",
                        candidate.title,
                    }, " "),
                    display = make_display,
                }
            end,
        }),
        sorter = sorters.empty(),
        default_selection_index = 1,
        attach_mappings = function()
            actions.select_default:replace(function(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    on_choice(selection.value)
                end
            end)
            return true
        end,
    }):find()
end

return M
```

- [ ] **Step 5: Implement the isolated command adapter**

Create `lua/mmp/github_commit_command.lua`:

```lua
local M = {}

function M.setup(get_commit)
    vim.api.nvim_create_user_command("GithubCommitOpen", function()
        require("mmp.github_commit").open(get_commit())
    end, {})
end

return M
```

- [ ] **Step 6: Replace the inline command implementation**

In `lua/mmp/init.lua`, replace the `open_commit_under_cursor_in_github` function and its `nvim_create_user_command` call:

```lua
-- Go to commit on github
local open_commit_under_cursor_in_github = function()
    local commit_hash = get_commit_under_cursor()
    local get_repo_url_cmd = "git config --get remote.origin.url | tr -d '\n'"
    -- Remove .git from the url
    get_repo_url_cmd = get_repo_url_cmd .. " | sed 's/\\.git$//'"
    local repo_url = vim.fn.system(get_repo_url_cmd)
    local url = repo_url .. "/commit/" .. commit_hash

    -- local cmd = "silent ! open -a Google\\ Chrome -n --args --new-window " .. url
    local cmd = "silent ! open -a 'Google Chrome' -n --args " .. url
    P(cmd)
    vim.cmd(cmd)
end

vim.api.nvim_create_user_command("GithubCommitOpen", open_commit_under_cursor_in_github, {})
```

with:

```lua
require("mmp.github_commit_command").setup(get_commit_under_cursor)
```

Leave the shared `get_commit_under_cursor()` helper unchanged because `CopyGithubPermalink` also uses it.

- [ ] **Step 7: Run all focused specs**

Run:

```sh
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_spec.lua"
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_picker_spec.lua"
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/github_commit_command_spec.lua"
```

Expected:

- `github commit resolver: ok`
- `github commit picker: ok`
- `github commit command: ok`

- [ ] **Step 8: Check syntax without starting the plugin manager**

Run:

```sh
nvim --headless -u NONE \
  "+lua assert(loadfile('lua/mmp/init.lua'))" \
  "+lua assert(loadfile('lua/mmp/github_commit.lua'))" \
  "+lua assert(loadfile('lua/mmp/github_commit_picker.lua'))" \
  "+lua assert(loadfile('lua/mmp/github_commit_command.lua'))" \
  "+qa!"
```

Expected: exit 0 with no network or browser activity. Do not load the full configuration for this check because `mmp.lazy` may install missing plugins; the focused `-u NONE` specs already cover the changed behavior and command wiring.

- [ ] **Step 9: Check formatting and commit Task 2**

Run:

```sh
STYLUA="$HOME/.local/share/nvim/mason/bin/stylua"
"$STYLUA" \
  lua/mmp/github_commit.lua \
  lua/mmp/github_commit_picker.lua \
  lua/mmp/github_commit_command.lua \
  tests/github_commit_spec.lua \
  tests/github_commit_picker_spec.lua \
  tests/github_commit_command_spec.lua
"$STYLUA" --check \
  lua/mmp/github_commit.lua \
  lua/mmp/github_commit_picker.lua \
  lua/mmp/github_commit_command.lua \
  tests/github_commit_spec.lua \
  tests/github_commit_picker_spec.lua \
  tests/github_commit_command_spec.lua
git diff --check
git status --short
```

Expected: formatting and whitespace checks pass. Status contains only the new picker, command adapter, two new specs, and the intended `lua/mmp/init.lua` edit, plus the already committed design and plan history.

Commit only Task 2 files:

```sh
G=/opt/homebrew/bin/git
$G add \
  lua/mmp/github_commit_picker.lua \
  lua/mmp/github_commit_command.lua \
  lua/mmp/init.lua \
  tests/github_commit_picker_spec.lua \
  tests/github_commit_command_spec.lua
$G commit -m "Open blamed commits in merged PRs"
```

### Task 3: Final verification and documentation commit

**Depends on:** Tasks 1 and 2

**Files:**
- Modify: `common/nvim/.config/nvim/docs/superpowers/specs/2026-09-01-github-commit-open-merged-pr-design.md`
- Create: `common/nvim/.config/nvim/docs/superpowers/plans/2026-09-01-github-commit-open-merged-pr.md`

- [ ] **Step 1: Run the complete focused test set once more from a clean process**

Run:

```sh
for spec in github_commit_spec.lua github_commit_picker_spec.lua; do
  nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/$spec" || exit 1
done
nvim --headless -u NONE "+set runtimepath^=$PWD" \
  "+luafile tests/github_commit_command_spec.lua"
```

Expected:

- `github commit resolver: ok`
- `github commit picker: ok`
- `github commit command: ok`

- [ ] **Step 2: Verify the real example without opening a browser**

Run these read-only remote calls:

```sh
gh search prs 5ef9def9bb4c7212edfa90db368b255db4d686d0 \
  --repo shop/world --merged --limit 1000 \
  --json number,title,state,closedAt,url

gh api repos/shop/world/pulls/1006544 \
  --jq '{number, merged, merged_at, merge_commit_sha, title, html_url}'

gh api --paginate --slurp 'repos/shop/world/pulls/1006544/commits?per_page=100' | jq -r '.[][].sha' | grep '^5ef9def9bb4c7212edfa90db368b255db4d686d0$'
```

Expected:

- Search returns merged PR `1006544`.
- PR details report `merged: true`.
- The paginated commit list contains the exact full SHA.

This confirms the example data used by the deterministic spec remains true without launching Chrome.

- [ ] **Step 3: Inspect final scope**

Run:

```sh
G=/opt/homebrew/bin/git
$G status --short
$G diff master...HEAD --stat
$G diff master...HEAD -- \
  lua/mmp/github_commit.lua \
  lua/mmp/github_commit_picker.lua \
  lua/mmp/github_commit_command.lua \
  lua/mmp/init.lua \
  tests/github_commit_spec.lua \
  tests/github_commit_picker_spec.lua \
  tests/github_commit_command_spec.lua
```

Expected: only the approved design, plan, resolver, picker, command wiring, and focused specs differ from `master`. The original dirty checkout remains untouched.

- [ ] **Step 4: Commit the planning documents**

The REST pagination clarification in the design and this implementation plan are intentionally uncommitted when execution begins. Commit them together:

```sh
G=/opt/homebrew/bin/git
$G add \
  docs/superpowers/specs/2026-09-01-github-commit-open-merged-pr-design.md \
  docs/superpowers/plans/2026-09-01-github-commit-open-merged-pr.md
$G commit -m "Document merged PR implementation"
```

Expected: the worktree is clean and the commit contains documentation only.
