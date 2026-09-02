-- Run with: nvim --headless "+luafile tests/aerial_java_records_spec.lua"

local function check(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function run()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.cmd("noautocmd setlocal filetype=java")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "public sealed interface SourcePlan {",
        "    record MySql(String primaryKey) implements SourcePlan {",
        "        public MySql {",
        "            primaryKey = required(primaryKey);",
        "        }",
        "    }",
        "",
        "    record Yugabyte(String databaseName) implements SourcePlan {}",
        "",
        "    private static String required(String value) {",
        "        return value;",
        "    }",
        "}",
    })

    require("aerial").sync_load()
    require("aerial.backends.treesitter").fetch_symbols_sync(bufnr)

    local actual = vim.tbl_map(function(item)
        return { item.level, item.kind, item.name }
    end, require("aerial.data").get(bufnr).flat_items)
    local expected = {
        { 0, "Interface", "SourcePlan" },
        { 1, "Class", "MySql" },
        { 2, "Constructor", "MySql" },
        { 1, "Class", "Yugabyte" },
        { 1, "Method", "required" },
    }
    check(
        vim.deep_equal(actual, expected),
        "unexpected Java record outline:\n" .. vim.inspect(actual)
    )
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
    io.stderr:write("aerial_java_records_spec failure:\n" .. tostring(err) .. "\n")
    vim.cmd("cquit 1")
end

print("Aerial Java records: ok")
vim.cmd("qa")
