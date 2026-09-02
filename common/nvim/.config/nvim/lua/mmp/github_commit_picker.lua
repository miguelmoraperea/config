local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

local M = {}

local displayer = entry_display.create({
	separator = " ",
	items = {
		{ width = 10 },
		{ width = 8 },
		{ width = 12 },
		{ remaining = true },
	},
})

local function make_display(entry)
	local candidate = entry.value
	return displayer({
		{ candidate.provider, "TelescopeResultsIdentifier" },
		{ "#" .. candidate.number, "TelescopeResultsNumber" },
		{ candidate.merged_at:sub(1, 10), "TelescopeResultsComment" },
		{ candidate.title },
	})
end

local function make_entry(candidate)
	return {
		value = candidate,
		ordinal = string.format(
			"%s #%s %s %s",
			candidate.provider,
			candidate.number,
			candidate.merged_at,
			candidate.title
		),
		display = make_display,
	}
end

function M.select(candidates, on_choice)
	pickers
		.new({}, {
			prompt_title = "Merged pull requests",
			finder = finders.new_table({
				results = candidates,
				entry_maker = make_entry,
			}),
			sorter = sorters.empty(),
			default_selection_index = 1,
			attach_mappings = function()
				actions.select_default:replace(function(prompt_buffer)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_buffer)
					if selection then
						on_choice(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
