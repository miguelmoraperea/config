# Gitstream-Aware Neovim PR Base Implementation Plan

> For agentic workers: REQUIRED: load the `subagent-driven-development`
> Superpowers skill with `superpowers_skill` (if subagents are available),
> or load `executing-plans` with the same tool to implement this plan.

Goal: Make PR-relative Neovim features use the current PR's real base for both Gitstream and GitHub, with Gitstream preferred when a Gitstream remote exists.

Architecture: Add a focused synchronous PR-base resolver that detects repository providers from remotes, queries `gs` first for Gitstream repositories, falls back to `gh` when GitHub is available, and returns the local merge base with the provider's base SHA. Route the existing Telescope and GitSigns consumers through this resolver while retaining the current trunk inference only when neither provider supplies PR metadata.

Tech Stack: Neovim Lua, `vim.system`, `vim.json`, `gs`, `gh`, headless Neovim Lua specs.

### Task 1: Resolve and share provider-aware PR bases

Files:
- Create: `common/nvim/.config/nvim/lua/mmp/pr_base.lua`
- Create: `common/nvim/.config/nvim/tests/pr_base_spec.lua`
- Modify: `common/nvim/.config/nvim/lua/mmp/pr_gitsigns.lua:41-58`
- Modify: `common/nvim/.config/nvim/lua/mmp/telescope.lua:800-816,1024-1027`

- [ ] Step 1: Write the failing resolver and consumer test

Create `tests/pr_base_spec.lua` with routed fake command results. Cover these independent cases:

1. A repository with Gitstream and GitHub remotes queries `gs pr list --head <branch> --json --limit 1`, uses its `baseSha`, computes `git merge-base HEAD <baseSha>`, and does not call `gh` when `gs` succeeds.
2. A GitHub-only repository queries `gh pr view --json baseRefOid -q .baseRefOid` and computes its merge base.
3. A dual-provider repository falls back from an empty Gitstream PR result to GitHub metadata.
4. Malformed or missing provider metadata returns `nil` rather than raising.
5. Provider detection considers only recognized hosts on fetch remotes, not push-only or substring matches.
6. `pr_gitsigns.get_merge_base()` returns the shared resolver's result without running trunk inference when PR metadata exists.
7. `pr_gitsigns.get_merge_base()` retains its existing `git cherry` and trunk fallback when the shared resolver returns `nil`.
8. Verify `telescope.lua` statically by reading its source text, not by requiring the plugin-heavy module: it no longer defines `get_pr_merge_base` or references `gh pr view`, and both `pr_commits` and `branch_changed_files` call `require("mmp.pr_gitsigns").get_merge_base()`.

Use this complete test harness. For cases 6 and 7, it replaces and restores `package.loaded["mmp.pr_base"]`, matching the adapter override pattern in `github_commit_spec.lua`:

```lua
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

local function with_pr_base(result, system, callback)
    local previous_base = package.loaded["mmp.pr_base"]
    local previous_gitsigns = package.loaded["mmp.pr_gitsigns"]
    local previous_system = vim.fn.system
    package.loaded["mmp.pr_base"] = { get_merge_base = function() return result end }
    package.loaded["mmp.pr_gitsigns"] = nil
    vim.fn.system = system

    local succeeded, message = xpcall(function()
        callback(require("mmp.pr_gitsigns"))
    end, debug.traceback)

    vim.fn.system = previous_system
    package.loaded["mmp.pr_base"] = previous_base
    package.loaded["mmp.pr_gitsigns"] = previous_gitsigns
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
    vim.fn.system("true")
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
end

local function run()
    test_gitstream_precedes_github()
    test_github_repository()
    test_github_fallback_after_gitstream_miss()
    test_malformed_gitstream_response()
    test_fetch_remote_host_detection()
    test_pr_gitsigns_prefers_provider_base()
    test_pr_gitsigns_retains_trunk_fallback()
    test_telescope_uses_shared_base()
end

local success, message = xpcall(run, debug.traceback)
if not success then
    io.stderr:write("pr_base_spec failure:\n" .. tostring(message) .. "\n")
    vim.cmd("cquit 1")
end

print("PR base resolver: ok")
vim.cmd("qa!")
```

The desired public API is:

```lua
local merge_base = require("mmp.pr_base").get_merge_base(optional_dependencies)
```

Dependencies are injectable only for tests:

```lua
{
    run = function(command)
        return { code = 0, stdout = "...", stderr = "" }
    end,
    decode = function(raw)
        return vim.json.decode(raw)
    end,
}
```

The real `gs pr list --head miguelmora/sandworm-sweep-run --json --limit 1` response was verified on 2026-09-02. Its top level is a bare JSON array, and its first object contains:

```json
[{"number":2034697,"baseRef":"miguelmora/sandworm-sweep-prepare","baseSha":"c06847f7fe935a3f20ceb149386a288991aa8178","headSha":"66b5340e73119a5f9e89458bbbe6b5e382cb123a"}]
```

The new resolver needs only provider presence, unlike `github_commit.lua`, which also needs repository identity and remote priority. Its narrower remote parser should still follow the established safety rules: inspect fetch lines only, parse the URL host, and accept only exact `gitstream.shopify.io` and `github.com` hosts.

- [ ] Step 2: Run the new spec and verify it fails

Run:

```sh
cd common/nvim/.config/nvim
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/pr_base_spec.lua"
```

Expected: FAIL because `lua/mmp/pr_base.lua` does not exist.

- [ ] Step 3: Implement the minimal shared resolver

Create `lua/mmp/pr_base.lua` with these behaviors:

```lua
local M = {}

local function default_run(command)
    local result = vim.system(command, { text = true }):wait()
    return {
        code = result.code or 1,
        stdout = result.stdout or "",
        stderr = result.stderr or "",
    }
end

local function default_decode(raw)
    return vim.json.decode(raw)
end

local function dependencies(overrides)
    overrides = overrides or {}
    return {
        run = overrides.run or default_run,
        decode = overrides.decode or default_decode,
    }
end

local function successful_output(deps, command)
    local result = deps.run(command)
    if not result or result.code ~= 0 then
        return nil
    end
    return result.stdout or ""
end

local function valid_sha(value)
    return type(value) == "string" and #value == 40 and value:match("^%x+$") ~= nil
end

local function remote_host(url)
    local _, remainder = url:match("^([%a][%w+.-]*)://(.+)$")
    if remainder then
        local authority = remainder:match("^([^/]+)")
        if not authority then
            return nil
        end
        return (authority:match("@([^@]+)$") or authority):gsub(":%d+$", ""):lower()
    end

    local host = url:match("^[^@%s]+@([^:%s]+):")
    return host and host:lower() or nil
end

local function discover_providers(remotes)
    local providers = {}
    for line in remotes:gmatch("[^\r\n]+") do
        local url = line:match("^%S+%s+(%S+)%s+%(fetch%)%s*$")
        local host = url and remote_host(url) or nil
        if host == "gitstream.shopify.io" then
            providers.gitstream = true
        elseif host == "github.com" then
            providers.github = true
        end
    end
    return providers
end

local function gitstream_base(deps)
    local branch = vim.trim(successful_output(deps, { "git", "rev-parse", "--abbrev-ref", "HEAD" }) or "")
    if branch == "" or branch == "HEAD" then
        return nil
    end

    local raw = successful_output(deps, {
        "gs", "pr", "list", "--head", branch, "--json", "--limit", "1",
    })
    if not raw then
        return nil
    end

    local decoded, pull_requests = pcall(deps.decode, raw)
    if not decoded then
        return nil
    end
    local base_sha = type(pull_requests) == "table"
        and type(pull_requests[1]) == "table"
        and pull_requests[1].baseSha
        or nil
    return valid_sha(base_sha) and base_sha or nil
end

local function github_base(deps)
    local base_sha = vim.trim(successful_output(deps, {
        "gh", "pr", "view", "--json", "baseRefOid", "-q", ".baseRefOid",
    }) or "")
    return valid_sha(base_sha) and base_sha or nil
end

function M.get_merge_base(overrides)
    local deps = dependencies(overrides)
    local remotes = successful_output(deps, { "git", "remote", "-v" })
    if not remotes then
        return nil
    end

    local providers = discover_providers(remotes)
    local base_sha
    if providers.gitstream then
        base_sha = gitstream_base(deps)
    end
    if not base_sha and providers.github then
        base_sha = github_base(deps)
    end
    if not base_sha then
        return nil
    end

    local merge_base = vim.trim(successful_output(deps, {
        "git", "merge-base", "HEAD", base_sha,
    }) or "")
    return valid_sha(merge_base) and merge_base or nil
end

return M
```

In `pr_gitsigns.lua`, remove the GitHub-only local resolver and make the first step of its existing `get_merge_base()`:

```lua
local pr_merge_base = require("mmp.pr_base").get_merge_base()
if pr_merge_base then
    return pr_merge_base
end
```

Keep the existing `git cherry` and trunk merge-base fallback unchanged.

In `telescope.lua`, remove its duplicate GitHub-only resolver. Both `pr_commits` and `branch_changed_files` should obtain their base only through:

```lua
local merge_base = require("mmp.pr_gitsigns").get_merge_base()
```

- [ ] Step 4: Run the new spec and verify it passes

Run:

```sh
cd common/nvim/.config/nvim
nvim --headless -u NONE "+set runtimepath^=$PWD" "+luafile tests/pr_base_spec.lua"
```

Expected: PASS with `PR base resolver: ok`.

- [ ] Step 5: Run focused syntax checks

Run:

```sh
cd common/nvim/.config/nvim
for file in lua/mmp/pr_base.lua lua/mmp/pr_gitsigns.lua lua/mmp/telescope.lua; do
  nvim --headless -u NONE "+lua assert(loadfile('$file'))" +qa
done
```

Expected: all changed Lua modules compile without errors.

- [ ] Step 6: Verify against the reported Gitstream stack

Re-read `gs pr list --head miguelmora/sandworm-sweep-run --json --limit 1` first. If the PR has moved, use its current `baseSha` and record the change instead of treating the stale recorded SHA as a resolver failure.

Run from `/Users/miguel/world/trees/miguelmora--sandworm-sweep-run/src`:

```sh
nvim --headless -u NONE \
  "+set runtimepath^=/Users/miguel/Desktop/git/miguelmora--nvim-gitstream-pr-base/common/nvim/.config/nvim" \
  "+lua local base = require('mmp.pr_base').get_merge_base(); assert(base == 'c06847f7fe935a3f20ceb149386a288991aa8178', tostring(base)); print(base)" \
  +qa
git diff --name-only c06847f7fe935a3f20ceb149386a288991aa8178..HEAD
```

Expected: the resolver prints `c06847f7fe935a3f20ceb149386a288991aa8178` and the diff contains the six files from PR `#2034697`, excluding `SweepPrepareTask.java` from parent PR `#2033535`.

- [ ] Step 7: Commit

```sh
git add common/nvim/.config/nvim/lua/mmp/pr_base.lua \
  common/nvim/.config/nvim/lua/mmp/pr_gitsigns.lua \
  common/nvim/.config/nvim/lua/mmp/telescope.lua \
  common/nvim/.config/nvim/tests/pr_base_spec.lua \
  docs/superpowers/plans/2026-09-02-nvim-gitstream-pr-base.md
git commit -m "Support Gitstream PR bases in Neovim"
```
