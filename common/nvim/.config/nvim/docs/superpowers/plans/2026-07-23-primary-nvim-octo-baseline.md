# Primary Neovim Octo Baseline Implementation Plan

> For agentic workers: REQUIRED: Use subagent-driven-development
> (if subagents available) or executing-plans to implement this plan.

**Goal:** Install a minimal Octo configuration in Miguel's primary Neovim alongside the existing TeamPR, Diffview, and Gitsigns workflows.

**Architecture:** Add one independently removable Lazy plugin specification under `lua/plugins/`. Exercise it through a focused headless Lua specification that loads the real plugin, checks its applied configuration and mappings, preserves TeamPR, and inspects Octo's health report.

**Tech Stack:** Neovim 0.12, Lua, lazy.nvim, Octo.nvim, Telescope, Plenary, GitHub CLI.

## File structure

- Create `lua/plugins/octo.lua`: owns the complete Octo plugin declaration, options, dependencies, and discovery mappings.
- Create `tests/octo_spec.lua`: owns focused headless configuration, mapping, coexistence, and health assertions.
- Modify `lazy-lock.json`: adds only the resolved `octo.nvim` revision.

### Task 1: Add and verify the Octo baseline

**Files:**
- Create: `tests/octo_spec.lua`
- Create: `lua/plugins/octo.lua`
- Modify: `lazy-lock.json`

- [ ] **Step 1: Snapshot unrelated in-progress changes**

Run:

```bash
/opt/homebrew/bin/git status --short > /tmp/nvim-octo-status-before.txt
/opt/homebrew/bin/git diff -- \
  lua/mmp/cpp.lua \
  lua/mmp/cpp_setup_instructions.md \
  lua/mmp/init.lua \
  lua/mmp/jdtls_setup.lua \
  lua/mmp/lazy.lua \
  lua/mmp/lsp.lua \
  lua/mmp/null-ls.lua \
  lua/mmp/nvim-cmp.lua \
  lua/mmp/rust.lua \
  lua/mmp/telescope.lua \
  lua/plugins/core.lua \
  lua/plugins/rust.lua \
  ../../../tmux/dot-tmux.conf > /tmp/nvim-octo-unrelated-before.diff
shasum lua/mmp/health.lua lua/mmp/mason.lua > /tmp/nvim-octo-untracked-before.sha
cp lazy-lock.json /tmp/nvim-octo-lazy-lock-before.json
```

Expected: all commands succeed; no files are modified.

- [ ] **Step 2: Write the failing headless specification**

Create `tests/octo_spec.lua`:

```lua
local ok, err = xpcall(function()
    local function assert_equal(actual, expected, label)
        assert(actual == expected, string.format("%s: expected %q, got %q", label, expected, actual))
    end

    local specs = dofile("lua/plugins/octo.lua")
    local spec = specs[1]
    assert_equal(spec[1], "pwntester/octo.nvim", "plugin")

    local expected_mappings = {
        ["<leader>oo"] = "Octo actions",
        ["<leader>op"] = "Octo pull requests",
        ["<leader>oi"] = "Octo issues",
        ["<leader>on"] = "Octo notifications",
        ["<leader>os"] = "Octo search current repository",
        ["<leader>or"] = "Browse PR review read-only",
    }

    for _, key in ipairs(spec.keys) do
        if expected_mappings[key[1]] == key.desc then
            expected_mappings[key[1]] = nil
        end
    end
    assert(next(expected_mappings) == nil, "plugin specification is missing or misdescribing an Octo mapping")

    local octo_ok, octo_err = pcall(require, "octo")
    assert(octo_ok, "Octo failed to load: " .. tostring(octo_err))
    assert(vim.fn.exists(":Octo") == 2, ":Octo command is unavailable")

    local config = require("octo.config").values
    assert_equal(config.picker, "telescope", "picker")
    assert_equal(config.default_remote[1], "github", "preferred remote")
    assert(config.enable_builtin == true, "built-in action picker must be enabled")
    assert(config.use_local_fs == false, "reviews must use GitHub-hosted files")
    assert(config.reviews.auto_show_threads == true, "review threads must appear automatically")
    assert_equal(config.reviews.focus, "right", "review focus")

    for lhs in pairs({
        ["<leader>oo"] = true,
        ["<leader>op"] = true,
        ["<leader>oi"] = true,
        ["<leader>on"] = true,
        ["<leader>os"] = true,
        ["<leader>or"] = true,
    }) do
        local mapping = vim.fn.maparg(lhs, "n", false, true)
        assert(next(mapping) ~= nil, "missing active mapping " .. lhs)
    end

    assert(vim.fn.exists(":TeamPR") == 2, ":TeamPR must remain available")

    vim.cmd("checkhealth octo")
    local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    assert(report:find("octo", 1, true), "Octo health report was not generated")
    assert(not report:match("%f[%a]ERROR%f[%A]"), "Octo health reported an error:\n" .. report)
end, debug.traceback)

if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end

print("primary Octo baseline: ok")
vim.cmd("qa")
```

- [ ] **Step 3: Run the test and verify it fails for the missing plugin specification**

Run:

```bash
nvim --headless "+luafile tests/octo_spec.lua"
```

Expected: exit non-zero with an error that `lua/plugins/octo.lua` cannot be opened.

- [ ] **Step 4: Add the minimal Octo plugin specification**

Create `lua/plugins/octo.lua`:

```lua
return {
    {
        "pwntester/octo.nvim",
        cmd = "Octo",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            picker = "telescope",
            default_remote = { "github", "upstream", "origin" },
            enable_builtin = true,
            use_local_fs = false,
            reviews = {
                auto_show_threads = true,
                focus = "right",
            },
        },
        keys = {
            { "<leader>oo", "<cmd>Octo<cr>", desc = "Octo actions" },
            { "<leader>op", "<cmd>Octo pr list<cr>", desc = "Octo pull requests" },
            { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "Octo issues" },
            { "<leader>on", "<cmd>Octo notification list<cr>", desc = "Octo notifications" },
            {
                "<leader>os",
                function()
                    require("octo.utils").create_base_search_command({ include_current_repo = true })
                end,
                desc = "Octo search current repository",
            },
            { "<leader>or", "<cmd>Octo review browse<cr>", desc = "Browse PR review read-only" },
        },
    },
}
```

- [ ] **Step 5: Install only Octo and verify the lockfile delta**

Run:

```bash
nvim --headless "+Lazy! install octo.nvim" +qa
python3 - <<'PY'
import json

with open('/tmp/nvim-octo-lazy-lock-before.json') as f:
    before = json.load(f)
with open('lazy-lock.json') as f:
    after = json.load(f)

changed = {key for key in before.keys() | after.keys() if before.get(key) != after.get(key)}
assert changed == {'octo.nvim'}, f'unexpected lockfile changes: {sorted(changed)}'
print('lazy-lock: only octo.nvim added')
PY
```

Expected: Octo installs successfully and the Python check prints `lazy-lock: only octo.nvim added`.

- [ ] **Step 6: Run the focused test and verify it passes**

Run:

```bash
nvim --headless "+luafile tests/octo_spec.lua"
```

Expected: exit zero and print `primary Octo baseline: ok`.

- [ ] **Step 7: Verify the original unrelated changes are byte-for-byte untouched**

Run:

```bash
/opt/homebrew/bin/git diff -- \
  lua/mmp/cpp.lua \
  lua/mmp/cpp_setup_instructions.md \
  lua/mmp/init.lua \
  lua/mmp/jdtls_setup.lua \
  lua/mmp/lazy.lua \
  lua/mmp/lsp.lua \
  lua/mmp/null-ls.lua \
  lua/mmp/nvim-cmp.lua \
  lua/mmp/rust.lua \
  lua/mmp/telescope.lua \
  lua/plugins/core.lua \
  lua/plugins/rust.lua \
  ../../../tmux/dot-tmux.conf > /tmp/nvim-octo-unrelated-after.diff
cmp /tmp/nvim-octo-unrelated-before.diff /tmp/nvim-octo-unrelated-after.diff
shasum -c /tmp/nvim-octo-untracked-before.sha
```

Expected: `cmp` exits zero and both untracked-file checks report `OK`.

- [ ] **Step 8: Commit only the Octo implementation**

Run:

```bash
/opt/homebrew/bin/git add lua/plugins/octo.lua tests/octo_spec.lua lazy-lock.json
/opt/homebrew/bin/git diff --cached --name-only
/opt/homebrew/bin/git commit -m "Add Octo to primary Neovim workflow"
```

Expected: the staged-name list contains exactly the three intended files; unrelated dirty files remain unstaged.

- [ ] **Step 9: Perform the interactive mapping smoke test**

Restart primary Neovim in a GitHub repository and press `<leader>oo`.

Expected: Octo's action picker opens through Telescope. `:TeamPR` remains available and unchanged.
