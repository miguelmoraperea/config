-- Run with: nvim --headless "+luafile tests/gitsigns_rename_spec.lua"

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

    local old_path = repo .. "/old_module.lua"
    local new_path = repo .. "/new_module.lua"
    vim.fn.writefile({
        "local M = {}",
        "",
        "function M.answer()",
        "    return 1",
        "end",
        "",
        "return M",
    }, old_path)
    git("add", "old_module.lua")
    git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "baseline")
    local base = vim.trim(vim.fn.system({ "git", "-C", repo, "rev-parse", "HEAD" }))

    git("mv", "old_module.lua", "new_module.lua")
    vim.fn.writefile({
        "local M = {}",
        "",
        "function M.answer()",
        "    return 2",
        "end",
        "",
        "return M",
    }, new_path)
    git("add", "new_module.lua")
    git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "rename module")

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

    vim.cmd.edit(vim.fn.fnameescape(new_path))
    local bufnr = vim.api.nvim_get_current_buf()
    local found_change = vim.wait(3000, function()
        local hunks = require("gitsigns").get_hunks(bufnr)
        return hunks and #hunks == 1 and hunks[1].type == "change"
    end, 20)
    check(found_change, "gitsigns treated the renamed file as entirely new")
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(repo, "rf")
if not ok then
    io.stderr:write("gitsigns_rename_spec failure:\n" .. tostring(err) .. "\n")
    vim.cmd("cquit 1")
end

print("Gitsigns renamed-file diff: ok")
vim.cmd("qa")
