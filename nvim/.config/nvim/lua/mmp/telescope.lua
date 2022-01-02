local actions = require('telescope.actions')
local action_state = require "telescope.actions.state"
local utils = require('telescope.utils')
local entry_display = require('telescope.pickers.entry_display')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local previewers = require('telescope.previewers')

require('telescope').setup{
    defaults = {
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case'
        },
        prompt_prefix = "> ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "vertical",
        layout_config = {
            horizontal = {
                width = 0.75,
                prompt_position = "top",
                preview_cutoff = 120
            },
            vertical = {
                width = 0.7,
            }
        },
        file_sorter = require'telescope.sorters'.get_fzy_sorter,
        file_ignore_patterns = {},
        generic_sorter =  require'telescope.sorters'.get_generic_fuzzy_sorter,
        path_display = {},
        winblend = 0,
        border = {},
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰'},
        color_devicons = true,
        use_less = true,
        set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
        file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
        grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
        qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,

        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker
    },
    extensions = {
        fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        }
    }
}

require('telescope').load_extension('fzy_native')
require('telescope').load_extension('file_browser')

local M = {}

M.search_dotfiles = function()
    require("telescope.builtin").find_files({
        prompt_title = "< VimRC >",
        cwd = "~/Desktop/git/config",
        hidden = true,
    })
end

M.git_branches = function()
    require("telescope.builtin").git_branches({
        attach_mappings = function(_, map)
            map('i', '<c-d>', actions.git_delete_branch)
            map('n', '<c-d>', actions.git_delete_branch)
            return true
        end
    })
end

M.spellcheck = function()
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local make_entry = require('telescope.make_entry')

    local locations = vim.fn.getqflist()

    if vim.tbl_isempty(locations) then
        return
    end

    pickers.new({
        prompt_title  = 'SpellCheck',
        finder = finders.new_table {
            results = locations,
            entry_maker = make_entry.gen_from_quickfix(),
        },
    }):find()
end

M.find_files_under = function()
    require("telescope.builtin").find_files({
        prompt_title = "< Find files under... >",
        cwd = vim.fn.expand('%:p:h')
    })
end

M.mappings = function()
    -- TODO: When selected, open the file where the mapping is defined
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local make_entry = require('telescope.make_entry')

    local map_output = vim.api.nvim_exec('map', true)

    local locations = {}
    for line in map_output:gmatch("([^\n]*)\n?") do
        table.insert(locations, line)
    end

    if vim.tbl_isempty(locations) then
        return
    end

    pickers.new({
        prompt_title  = 'Mappings',
        finder = finders.new_table {
            results = locations,
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
    }):find()
end

M.grep_word_under_cursor = function()
  opts = opts or {}

  local register = vim.fn.expand('<cword>')

  opts.path_display = { "absolute" }
  opts.word_match = "-w"
  opts.search = register

  require("telescope.builtin").grep_string(opts)
end

M.buffers = function()
    require("telescope.builtin").buffers({
        attach_mappings = function(_, map)
            map('i', '<c-d>', actions.delete_buffer)
            return true
        end
    })
end

local function set_background(content)
    local cmd = "feh --bg-fill "
            .. content
    vim.fn.system(cmd)
end

local function delete_background(prompt_bufnr, map)
    local function rm_background()
        local content = require("telescope.actions.state").get_selected_entry(
            prompt_bufnr
        )
        local file = content.cwd .. "/" .. content.value
        local cmd = "rm -f "
                .. file
        -- TODO: Add confirmation before deleting the file
        vim.fn.system(cmd)
    end

    map("i", "<C-d>", function()
        rm_background()
    end)

end

local function select_background(prompt_bufnr, map)
    local function set_the_background(close)
        local content = require("telescope.actions.state").get_selected_entry(
            prompt_bufnr
        )
        set_background(content.cwd .. "/" .. content.value)
        if close then
            require("telescope.actions").close(prompt_bufnr)
        end
    end

    map("i", "<C-p>", function()
        set_the_background()
    end)

    map("i", "<CR>", function()
        set_the_background(true)
    end)

end

local function image_selector(prompt, cwd)
    return function()
        require("telescope.builtin").find_files({
            prompt_title = prompt,
            cwd = cwd,
            previewer = false,

            attach_mappings = function(prompt_bufnr, map)
                select_background(prompt_bufnr, map)
                delete_background(propmt_bufnr, map)

                -- Please continue mapping (attaching additional key maps):
                -- Ctrl+n/p to move up and down the list.
                return true
            end,
        })
    end
end

M.background_selector = image_selector("< Background Selector > ", "~/Desktop/git/backgrounds")

local diff_commit = function(prompt_bufnr, mode)
  local selection = action_state.get_selected_entry()
  require("telescope.actions").close(prompt_bufnr)
  vim.cmd(string.format('call VimDiffView("%s")', selection.value))
end

M.git_commits = function(opts)
    local output = utils.get_os_command_output({ "git", "log", "--pretty=format:%h/%s/%an", "--abbrev-commit", "--", "."})

    local results = {}
    local parse_line = function(line)
        local fields = vim.split(line, "/", true)
        local entry = {
            hash = fields[1],
            subject = fields[2],
            author = fields[3],
        }
        local index = 1
        if entry.hash ~= "*" then
            index = #results + 1
        end
        -- P(results)
        table.insert(results, index, entry)
    end

    for _, line in ipairs(output) do
        parse_line(line)
    end

  local displayer = entry_display.create {
    separator = " ",
    items = {
            { width = 10 },
            { width = 80 },
            { width = 20},
        },
    }

  local make_display = function(entry)
    return displayer {
        { entry.hash },
        { entry.subject, "TelescopeResultsIdentifier" },
        { entry.author },
    }
  end

    local entry_maker = function(entry)
        entry.value = entry.hash
        entry.ordinal = entry.subject .. entry.author .. entry.hash
        entry.display = make_display
        return entry
    end

    opts.entry_maker = entry_maker

    pickers.new(opts, {
        prompt_title = "Custom Git Commits",
        finder = finders.new_table {
            results = results,
            entry_maker = function(entry)
                entry.value = entry.hash
                entry.ordinal = entry.subject .. entry.author .. entry.hash
                entry.display = make_display
                return entry
            end,
        },
    previewer = previewers.git_commit_message.new(opts),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(_, map)
        actions.select_default:replace(actions.git_checkout)
        map("i", "<c-d>", diff_commit)
        map("n", "<c-d>", diff_commit)
        return true
    end,
  }):find()
end

return M
