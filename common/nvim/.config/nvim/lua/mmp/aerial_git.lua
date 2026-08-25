-- Mirror gitsigns hunks onto the aerial symbol list: a symbol whose source
-- range overlaps a hunk gets the same sign and line highlight the file shows,
-- and a symbol that only exists in the diff base gets a red phantom row.
-- Follows the GitsignsToggleAll toggle (<Leader>gh).

local M = {}

local NS = vim.api.nvim_create_namespace("mmp_aerial_git")

local MARKERS = {
    add = { text = "┃", sign_hl = "GitSignsAdd", line_hl = "GitSignsAddLn" },
    change = { text = "┃", sign_hl = "GitSignsChange", line_hl = "GitSignsChangeLn" },
    delete = { text = "_", sign_hl = "GitSignsDelete", line_hl = "GitSignsDeleteLn" },
}

local PHANTOM_HL = "GitSignsDeleteVirtLn"
-- Virtual text only highlights the cells it occupies, so pad it the way
-- gitsigns pads its own deleted lines to fake a full-width background.
local PHANTOM_WIDTH = 300

local enabled = false
local attached = false
local parsing_base = false
local base_cache = {}

---Collapse touching/overlapping ranges so whole-symbol containment can be
---decided against a single range.
local function merge(ranges)
    table.sort(ranges, function(a, b)
        return a.first < b.first
    end)
    local i = 1
    while i < #ranges do
        local current, next_range = ranges[i], ranges[i + 1]
        if next_range.first <= current.last + 1 then
            current.last = math.max(current.last, next_range.last)
            table.remove(ranges, i + 1)
        else
            i = i + 1
        end
    end
end

---Respects gitsigns' change_base, so PR diff mode is picked up for free.
local function get_hunks(bufnr)
    local ok, gitsigns = pcall(require, "gitsigns")
    if not ok then
        return nil
    end
    return gitsigns.get_hunks(bufnr)
end

---Hunk line ranges in current-buffer coordinates.
local function hunk_ranges(hunks)
    local ranges = { added = {}, edited = {}, deleted = {} }
    for _, hunk in ipairs(hunks) do
        local count = hunk.added.count
        if count > 0 then
            local range = { first = hunk.added.start, last = hunk.added.start + count - 1 }
            table.insert(ranges.edited, range)
            if hunk.type == "add" then
                table.insert(ranges.added, range)
            end
        else
            -- A pure deletion owns no line, so anchor it on the survivor above.
            table.insert(ranges.deleted, math.max(hunk.added.start, 1))
        end
    end
    merge(ranges.added)

    return ranges
end

local function status_for(item, ranges)
    local first, last = item.lnum, item.end_lnum or item.lnum

    for _, range in ipairs(ranges.added) do
        if range.first <= first and range.last >= last then
            return "add"
        end
    end
    for _, range in ipairs(ranges.edited) do
        if range.first <= last and range.last >= first then
            return "change"
        end
    end
    for _, lnum in ipairs(ranges.deleted) do
        if lnum >= first and lnum <= last then
            return "delete"
        end
    end
end

---Text of the diff base, rebuilt by swapping every hunk's added lines back
---out for its removed ones.
local function base_lines(bufnr, hunks)
    local current = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local lines, idx = {}, 1

    for _, hunk in ipairs(hunks) do
        local keep_until = hunk.added.count > 0 and hunk.added.start - 1 or hunk.added.start
        while idx <= keep_until do
            lines[#lines + 1] = current[idx]
            idx = idx + 1
        end
        for i = 1, hunk.removed.count do
            lines[#lines + 1] = hunk.lines[i]:sub(2)
        end
        idx = idx + hunk.added.count
    end
    vim.list_extend(lines, current, idx)

    return lines
end

---Outline of the diff base. Treesitter only: no language server ever attaches
---to a scratch buffer.
local function base_symbols(bufnr, hunks)
    local ok, treesitter = pcall(require, "aerial.backends.treesitter")
    if not ok then
        return {}
    end

    local scratch = vim.api.nvim_create_buf(false, true)
    vim.bo[scratch].filetype = vim.bo[bufnr].filetype
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, base_lines(bufnr, hunks))

    parsing_base = true
    local parsed = pcall(treesitter.fetch_symbols_sync, scratch)
    parsing_base = false

    local data = require("aerial.data")
    local symbols = {}
    if parsed and data.has_symbols(scratch) then
        for _, item in data.get_or_create(scratch):iter({ skip_hidden = false }) do
            symbols[#symbols + 1] = {
                name = item.name,
                kind = item.kind,
                level = item.level,
                lnum = item.lnum,
            }
        end
    end

    data.delete_buf(scratch)
    vim.api.nvim_buf_delete(scratch, { force = true })

    return symbols
end

---change_base can move the diff without touching the buffer, and two bases can
---produce hunks of identical shape but different content, so the removed lines
---themselves have to be part of the key.
local function base_signature(bufnr, hunks)
    local parts = { vim.api.nvim_buf_get_changedtick(bufnr) }
    for _, hunk in ipairs(hunks) do
        parts[#parts + 1] = table.concat({
            hunk.removed.start,
            hunk.removed.count,
            hunk.added.start,
            hunk.added.count,
        }, ",")
        for i = 1, hunk.removed.count do
            parts[#parts + 1] = hunk.lines[i]
        end
    end
    return vim.fn.sha256(table.concat(parts, "\n"))
end

local function cached_base_symbols(bufnr, hunks)
    local signature = base_signature(bufnr, hunks)
    local cached = base_cache[bufnr]
    if not cached or cached.signature ~= signature then
        cached = { signature = signature, symbols = base_symbols(bufnr, hunks) }
        base_cache[bufnr] = cached
    end
    return cached.symbols
end

---The base is always parsed by treesitter while the live outline may come from
---a language server, and the two decorate differently: `alpha` vs `alpha()`.
---They also disagree on hierarchy, so the key deliberately ignores the parent.
local function symbol_key(name)
    local bare = vim.trim(name:match("^[^(]*") or "")
    return bare ~= "" and bare or name
end

---Base symbols with no counterpart in the live outline. Counted rather than
---set-tested so overloads collapsing from two to one still register.
local function deleted_symbols(bufnr, hunks)
    local data = require("aerial.data")

    local live = {}
    for _, item in data.get_or_create(bufnr):iter({ skip_hidden = false }) do
        local key = symbol_key(item.name)
        live[key] = (live[key] or 0) + 1
    end

    local gone = {}
    for _, item in ipairs(cached_base_symbols(bufnr, hunks)) do
        local key = symbol_key(item.name)
        if (live[key] or 0) > 0 then
            live[key] = live[key] - 1
        else
            gone[#gone + 1] = item
        end
    end

    return gone
end

---Where a base line number lands in the current buffer.
local function to_current_line(lnum, hunks)
    local delta = 0

    for _, hunk in ipairs(hunks) do
        if hunk.removed.count == 0 then
            if hunk.removed.start >= lnum then
                break
            end
        else
            local last = hunk.removed.start + hunk.removed.count - 1
            if lnum <= last then
                return lnum >= hunk.removed.start and hunk.added.start or lnum + delta
            end
        end
        delta = delta + hunk.added.count - hunk.removed.count
    end

    return lnum + delta
end

local function phantom_line(bufnr, item)
    local icon = require("aerial.config").get_icon(bufnr, item.kind, false)
    local text = string.format("%s%s %s", string.rep("  ", item.level), icon, item.name)
    local pad = PHANTOM_WIDTH - vim.api.nvim_strwidth(text)

    return { { text .. string.rep(" ", math.max(pad, 0)), PHANTOM_HL } }
end

---Aerial creates its window with signcolumn=no, so the gutter has to be
---re-enabled on every window showing the buffer.
local function set_gutter(aer_bufnr, on)
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(winid) == aer_bufnr then
            vim.api.nvim_set_option_value("signcolumn", on and "yes:1" or "no", { scope = "local", win = winid })
        end
    end
end

---@param bufnr integer either a source buffer or its aerial buffer
function M.refresh(bufnr)
    -- Parsing the base sets symbols on a scratch buffer, which re-enters here
    -- through the update_aerial_buffer wrapper.
    if parsing_base then
        return
    end

    local ok, util = pcall(require, "aerial.util")
    if not ok then
        return
    end

    local src_bufnr, aer_bufnr = util.get_buffers(bufnr)
    if not src_bufnr or not aer_bufnr or not vim.api.nvim_buf_is_valid(aer_bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(aer_bufnr, NS, 0, -1)
    set_gutter(aer_bufnr, enabled)
    if not enabled then
        return
    end

    local data = require("aerial.data")
    if not data.has_symbols(src_bufnr) then
        return
    end

    local hunks = get_hunks(src_bufnr)
    if not hunks or vim.tbl_isempty(hunks) then
        return
    end
    local ranges = hunk_ranges(hunks)

    -- Same walk aerial.render uses to lay out lines, so row tracks it exactly.
    -- It can still outrun the buffer while a render is pending.
    local line_count = vim.api.nvim_buf_line_count(aer_bufnr)
    local rows = {}
    for _, item in data.get_or_create(src_bufnr):iter({ skip_hidden = true }) do
        local row = #rows + 1
        if row > line_count then
            return
        end
        rows[row] = item.lnum

        local status = status_for(item, ranges)
        local marker = status and MARKERS[status]
        if marker then
            vim.api.nvim_buf_set_extmark(aer_bufnr, NS, row - 1, 0, {
                sign_text = marker.text,
                sign_hl_group = marker.sign_hl,
                line_hl_group = marker.line_hl,
                priority = 100,
            })
        end
    end
    if vim.tbl_isempty(rows) then
        return
    end

    local phantoms = {}
    for _, item in ipairs(deleted_symbols(src_bufnr, hunks)) do
        local target = to_current_line(item.lnum, hunks)
        local anchor
        for row, lnum in ipairs(rows) do
            if lnum >= target then
                anchor = row
                break
            end
        end

        local key = anchor or #rows
        phantoms[key] = phantoms[key] or { above = anchor ~= nil, lines = {} }
        table.insert(phantoms[key].lines, phantom_line(src_bufnr, item))
    end

    for row, phantom in pairs(phantoms) do
        vim.api.nvim_buf_set_extmark(aer_bufnr, NS, row - 1, 0, {
            virt_lines = phantom.lines,
            virt_lines_above = phantom.above,
            priority = 100,
        })
    end
end

function M.refresh_all()
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        M.refresh(vim.api.nvim_win_get_buf(winid))
    end
end

function M.set_enabled(value)
    enabled = value
    if package.loaded["aerial"] then
        M.refresh_all()
    end
end

function M.is_enabled()
    return enabled
end

---Call once, from aerial's own config, so nothing here forces it to load.
function M.attach()
    if attached then
        return
    end
    attached = true

    -- aerial fires no post-render event, so wrap the single function that
    -- rebuilds the buffer; this covers open, collapse, expand and re-parse.
    local render = require("aerial.render")
    local update_aerial_buffer = render.update_aerial_buffer
    render.update_aerial_buffer = function(buf)
        update_aerial_buffer(buf)
        M.refresh(buf or 0)
    end

    local group = vim.api.nvim_create_augroup("MmpAerialGit", { clear = true })

    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "GitSignsUpdate",
        callback = function(args)
            local bufnr = args.data and args.data.buffer
            if bufnr then
                M.refresh(bufnr)
            else
                M.refresh_all()
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = group,
        callback = function(args)
            M.refresh(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        group = group,
        callback = function(args)
            base_cache[args.buf] = nil
        end,
    })

    M.refresh_all()
end

return M
