local function check(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function run()
	local captured = {
		closed = {},
	}
	local selected_entry
	local sorter = {}

	package.preload["telescope.pickers"] = function()
		return {
			new = function(options, specification)
				captured.picker_options = options
				captured.picker_specification = specification
				return {
					find = function()
						captured.started = true
					end,
				}
			end,
		}
	end
	package.preload["telescope.finders"] = function()
		return {
			new_table = function(specification)
				captured.finder_specification = specification
				return { specification = specification }
			end,
		}
	end
	package.preload["telescope.sorters"] = function()
		return {
			empty = function()
				return sorter
			end,
		}
	end
	package.preload["telescope.pickers.entry_display"] = function()
		return {
			create = function(specification)
				captured.display_specification = specification
				return function(columns)
					return columns
				end
			end,
		}
	end
	package.preload["telescope.actions"] = function()
		return {
			select_default = {
				replace = function(_, callback)
					captured.selection_callback = callback
				end,
			},
			close = function(prompt_buffer)
				table.insert(captured.closed, prompt_buffer)
			end,
		}
	end
	package.preload["telescope.actions.state"] = function()
		return {
			get_selected_entry = function()
				return selected_entry
			end,
		}
	end

	local candidates = {
		{
			provider = "Meteorite",
			number = 20,
			merged_at = "2026-08-30T09:15:00Z",
			title = "Oldest merged pull request",
			url = "https://meteorite.example/pulls/20",
		},
		{
			provider = "GitHub",
			number = 40,
			merged_at = "2026-08-31T10:30:00Z",
			title = "Newer merged pull request",
			url = "https://github.example/pulls/40",
		},
	}
	local choices = {}
	local picker = require("mmp.github_commit_picker")
	picker.select(candidates, function(candidate)
		table.insert(choices, candidate)
	end)

	check(captured.started, "picker did not start")
	check(captured.picker_specification.prompt_title == "Merged pull requests", "picker title is incorrect")
	check(captured.finder_specification.results == candidates, "finder did not receive the exact candidate list")
	check(captured.finder_specification.results[1] == candidates[1], "finder changed the oldest-first order")
	check(captured.picker_specification.sorter == sorter, "picker did not use the empty sorter")
	check(captured.picker_specification.default_selection_index == 1, "picker did not select the first candidate")

	local first_entry = captured.finder_specification.entry_maker(candidates[1])
	check(first_entry.value == candidates[1], "entry did not preserve its candidate value")
	check(
		first_entry.ordinal == "Meteorite #20 2026-08-30T09:15:00Z Oldest merged pull request",
		"entry ordinal does not include all searchable fields"
	)
	local display = first_entry.display(first_entry)
	check(display[1][1] == "Meteorite", "display omitted the provider")
	check(display[2][1] == "#20", "display omitted the pull request number")
	check(display[3][1] == "2026-08-30", "display did not shorten the merge date")
	check(display[4][1] == "Oldest merged pull request", "display omitted the title")

	check(captured.picker_specification.attach_mappings(71, function() end) == true, "mappings did not return true")
	selected_entry = first_entry
	captured.selection_callback(71)
	check(captured.closed[1] == 71, "selection did not close the picker")
	check(choices[1] == candidates[1], "selection did not return the exact candidate")

	local cancelled = false
	picker.select(candidates, function()
		cancelled = true
	end)
	check(
		captured.picker_specification.attach_mappings(72, function() end) == true,
		"cancel mappings did not return true"
	)
	selected_entry = nil
	captured.selection_callback(72)
	check(captured.closed[2] == 72, "cancellation did not close the picker")
	check(not cancelled, "cancellation invoked on_choice")
end

local success, error_message = xpcall(run, debug.traceback)
if not success then
	io.stderr:write("github_commit_picker_spec failure:\n" .. tostring(error_message) .. "\n")
	vim.cmd("cquit 1")
end

print("github commit picker: ok")
vim.cmd("qa!")
