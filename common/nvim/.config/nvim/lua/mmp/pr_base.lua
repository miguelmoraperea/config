local M = {}

local function default_run(command)
    local succeeded, result = pcall(function()
        return vim.system(command, { text = true }):wait()
    end)
    if not succeeded then
        return { code = 1, stdout = "", stderr = tostring(result) }
    end
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
