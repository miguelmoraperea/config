-- Focused headless spec for the primary Octo baseline.
-- Run with: nvim --headless "+luafile tests/octo_spec.lua"

local function check(cond, message)
    if not cond then
        error(message, 2)
    end
end

local function run()
    -- Plugin spec file: first plugin must be pwntester/octo.nvim.
    local spec = dofile("lua/plugins/octo.lua")
    check(type(spec) == "table", "lua/plugins/octo.lua did not return a table")
    local octo_spec = spec[1]
    check(type(octo_spec) == "table", "first spec entry is not a table")
    check(
        octo_spec[1] == "pwntester/octo.nvim",
        "first plugin is not pwntester/octo.nvim, got: " .. tostring(octo_spec and octo_spec[1])
    )

    -- Exactly these six mappings, matched one spec entry per expectation.
    local expected = {
        { lhs = "<leader>oo", desc = "Octo actions" },
        { lhs = "<leader>op", desc = "Octo pull requests" },
        { lhs = "<leader>oi", desc = "Octo issues" },
        { lhs = "<leader>on", desc = "Octo notifications" },
        { lhs = "<leader>os", desc = "Octo search current repository" },
        { lhs = "<leader>or", desc = "Browse PR review read-only" },
    }
    local keys = octo_spec.keys
    check(type(keys) == "table", "octo spec has no keys table")
    check(#keys == #expected, string.format("expected %d key specs, found %d", #expected, #keys))

    local remaining = {}
    for i, key in ipairs(keys) do
        remaining[i] = key
    end
    for _, want in ipairs(expected) do
        local matched_index = nil
        for i, key in pairs(remaining) do
            if matched_index == nil and key[1] == want.lhs and key.desc == want.desc then
                matched_index = i
            end
        end
        check(
            matched_index ~= nil,
            string.format("missing key spec %s with desc %q", want.lhs, want.desc)
        )
        remaining[matched_index] = nil
    end

    -- Loading octo must leave the :Octo command available.
    require("octo")
    check(vim.fn.exists(":Octo") == 2, ":Octo command does not exist after require('octo')")

    -- Effective octo configuration.
    local conf = require("octo.config").values
    check(conf.picker == "telescope", "picker is not telescope, got: " .. tostring(conf.picker))
    check(
        conf.default_remote[1] == "github",
        "default_remote[1] is not github, got: " .. tostring(conf.default_remote and conf.default_remote[1])
    )
    check(conf.enable_builtin == true, "enable_builtin is not true")
    check(conf.use_local_fs == false, "use_local_fs is not false")
    check(conf.reviews.auto_show_threads == true, "reviews.auto_show_threads is not true")
    check(conf.reviews.focus == "right", "reviews.focus is not right, got: " .. tostring(conf.reviews.focus))

    -- All six normal-mode mappings must be active.
    for _, want in ipairs(expected) do
        local map = vim.fn.maparg(want.lhs, "n", false, true)
        check(
            type(map) == "table" and not vim.tbl_isempty(map),
            "normal-mode mapping not active: " .. want.lhs
        )
        check(
            map.desc == want.desc,
            string.format("mapping %s has desc %q, want %q", want.lhs, tostring(map.desc), want.desc)
        )
    end

    -- The existing team PR workflow must remain untouched.
    check(vim.fn.exists(":TeamPR") == 2, ":TeamPR command does not exist")

    -- Octo health report: mentions octo, and no frontier-delimited ERROR word.
    vim.cmd("checkhealth octo")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local text = table.concat(lines, "\n")
    check(text:find("octo", 1, true) ~= nil, "health buffer does not contain 'octo':\n" .. text)
    check(text:find("%f[%w]ERROR%f[%W]") == nil, "health buffer contains ERROR:\n" .. text)
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
    io.stderr:write("octo_spec failure:\n" .. tostring(err) .. "\n")
    vim.cmd("cquit 1")
end

print("primary Octo baseline: ok")
vim.cmd("qa")
