local actions = require('telescope.actions')

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
        prompt_prefix = ">",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
            width = 0.75,
            prompt_position = "top",
            preview_cutoff = 120,
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

local M = {}

M.search_dotfiles = function()
    require("telescope.builtin").find_files({
        prompt_title = "< VimRC >",
        cwd = "~/Desktop/git/config/nvim",
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

return M
