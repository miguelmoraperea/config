-- Run with: nvim --headless "+luafile tests/aerial_git_spec.lua"

local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local repo = vim.fn.tempname()

local function git(...)
    local args = { "git", "-C", repo, ... }
    local output = vim.fn.system(args)
    check(vim.v.shell_error == 0, table.concat(args, " ") .. " failed:\n" .. output)
end

local function run()
    vim.fn.mkdir(repo, "p")
    git("init", "-q")
    vim.fn.writefile({ "baseline" }, repo .. "/README.md")
    git("add", "README.md")
    git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "baseline")

    local base = vim.trim(vim.fn.system({ "git", "-C", repo, "rev-parse", "HEAD" }))
    local source = repo .. "/new_module.lua"
    vim.fn.writefile({
        "local M = {}",
        "",
        "function M.alpha()",
        "    return 1",
        "end",
        "",
        "function M.beta()",
        "    return 2",
        "end",
        "",
        "return M",
    }, source)
    git("add", "new_module.lua")
    git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "add module")

    local base_changed = false
    local base_error
    require("gitsigns").change_base(base, true, function(err)
        base_error = err
        base_changed = true
    end)
    check(vim.wait(3000, function()
        return base_changed
    end, 20), "gitsigns did not finish changing the diff base")
    check(not base_error, "gitsigns could not change the diff base: " .. tostring(base_error))

    vim.cmd.edit(vim.fn.fnameescape(source))
    local src_bufnr = vim.api.nvim_get_current_buf()
    local has_hunks = vim.wait(3000, function()
        local hunks = require("gitsigns").get_hunks(src_bufnr)
        return hunks and #hunks == 1 and hunks[1].type == "add"
    end, 20)
    check(has_hunks, "gitsigns did not expose the branch-added file as one added hunk")

    require("aerial").setup({})
    require("mmp.aerial_git").attach()
    vim.cmd("GitsignsToggleAll")

    local source_green = vim.wait(3000, function()
        local namespace = vim.api.nvim_get_namespaces().gitsigns_signs_
        local marks = vim.api.nvim_buf_get_extmarks(src_bufnr, namespace, 0, -1, { details = true })
        local green = 0
        for _, mark in ipairs(marks) do
            if mark[4].line_hl_group == "GitSignsAddLn" then
                green = green + 1
            end
        end
        return green == vim.api.nvim_buf_line_count(src_bufnr)
    end, 20)
    check(source_green, "GitsignsToggleAll did not highlight every source line green")

    vim.cmd("AerialOpen")

    local util = require("aerial.util")
    local data = require("aerial.data")
    local aer_bufnr
    local rendered = vim.wait(3000, function()
        local _, candidate = util.get_buffers(src_bufnr)
        aer_bufnr = candidate
        return aer_bufnr and data.has_symbols(src_bufnr) and vim.api.nvim_buf_line_count(aer_bufnr) > 1
    end, 20)
    check(rendered, "aerial did not render symbols for the new file")

    require("mmp.aerial_git").refresh(src_bufnr)
    local namespace = vim.api.nvim_get_namespaces().mmp_aerial_git
    local marks = vim.api.nvim_buf_get_extmarks(aer_bufnr, namespace, 0, -1, { details = true })

    local symbol_count = 0
    for _ in data.get_or_create(src_bufnr):iter({ skip_hidden = true }) do
        symbol_count = symbol_count + 1
    end
    local added_count = 0
    for _, mark in ipairs(marks) do
        if mark[4].line_hl_group == "GitSignsAddLn" then
            added_count = added_count + 1
        end
    end
    check(symbol_count > 0, "aerial found no symbols in the new file")
    check(
        added_count == symbol_count,
        string.format("expected %d green aerial symbols, found %d", symbol_count, added_count)
    )
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(repo, "rf")
if not ok then
    io.stderr:write("aerial_git_spec failure:\n" .. tostring(err) .. "\n")
    vim.cmd("cquit 1")
end

print("Aerial git highlighting: ok")
vim.cmd("qa")
