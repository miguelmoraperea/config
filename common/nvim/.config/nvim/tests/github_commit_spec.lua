local function check(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function same_list(actual, expected, message)
	check(#actual == #expected, string.format("%s: expected %d items, got %d", message, #expected, #actual))
	for index, value in ipairs(expected) do
		check(
			actual[index] == value,
			string.format("%s at %d: expected %q, got %q", message, index, value, actual[index])
		)
	end
end

local function command_key(command)
	return table.concat(command, "\0")
end

local function json(value)
	return vim.json.encode(value)
end

local function ok(stdout)
	return { code = 0, stdout = stdout or "", stderr = "" }
end

local function failed(stderr)
	return { code = 1, stdout = "", stderr = stderr or "failed" }
end

local function route(routes, command, result)
	routes[command_key(command)] = routes[command_key(command)] or {}
	table.insert(routes[command_key(command)], result)
end

local function remote_result(lines)
	return ok(table.concat(lines, "\n") .. "\n")
end

local function harness(routes, picker)
	local state = {
		commands = {},
		opened = {},
		notifications = {},
		picks = {},
		unexpected = nil,
	}

	local dependencies = {
		run = function(command, callback)
			table.insert(state.commands, command)
			local queue = routes[command_key(command)]
			if not queue or #queue == 0 then
				state.unexpected = "unexpected command: " .. table.concat(command, " ")
				callback(failed(state.unexpected))
				return
			end
			local result = table.remove(queue, 1)
			callback(result)
		end,
		open = function(url)
			table.insert(state.opened, url)
		end,
		notify = function(message, level)
			table.insert(state.notifications, { message = message, level = level })
		end,
		pick = function(items, on_choice)
			table.insert(state.picks, items)
			if picker then
				picker(items, on_choice)
			end
		end,
	}

	function state:check_routes()
		check(not self.unexpected, self.unexpected)
		for key, queue in pairs(routes) do
			check(#queue == 0, "unused route: " .. key:gsub("\0", " "))
		end
	end

	return dependencies, state
end

local function base_routes(remote_lines)
	local routes = {}
	route(routes, { "git", "remote", "-v" }, remote_result(remote_lines))
	return routes
end

local TARGET = "5ef9def9bb4c7212edfa90db368b255db4d686d0"
local OTHER = "1111111111111111111111111111111111111111"
local MERGE = "2222222222222222222222222222222222222222"

local function assert_failure(raw_hash, routes, expected_message)
	local dependencies, state = harness(routes)
	require("mmp.github_commit").open(raw_hash, dependencies)
	state:check_routes()
	check(#state.notifications == 1, "expected exactly one notification, got " .. #state.notifications)
	check(
		state.notifications[1].message:find(expected_message, 1, true) ~= nil,
		string.format("expected notification containing %q, got %q", expected_message, state.notifications[1].message)
	)
	check(#state.opened == 0, "failure opened a URL")
	check(#state.picks == 0, "failure opened a picker")
end

local function test_dual_remote_exact_github_result()
	local routes = base_routes({
		"backup\thttps://github.com/other/repository.git (fetch)",
		"stream\tssh://git@gitstream.shopify.io/other/repository.git (fetch)",
		"origin\tgit@gitstream.shopify.io:shop/world.git (fetch)",
		"origin\tssh://git@github.com/wrong/origin.git (fetch)",
		"upstream\thttps://github.com/wrong/upstream.git (fetch)",
		"github\tgit@github.com:shop/world.git (fetch)",
		"github\tgit@github.com:shop/world.git (push)",
	})
	route(routes, { "gs", "api", "repos/shop/world/commits/5EF9DEF" }, ok(json({ sha = TARGET:upper() })))
	route(routes, {
		"gh",
		"search",
		"prs",
		TARGET,
		"--repo",
		"shop/world",
		"--merged",
		"--limit",
		"1000",
		"--json",
		"number,title,state,closedAt,url",
	}, ok(json({ { number = 1006544, title = "result", state = "closed" } })))
	route(
		routes,
		{ "gh", "api", "repos/shop/world/pulls/1006544" },
		ok(json({
			number = 1006544,
			merged = true,
			title = "Exact GitHub PR",
			merged_at = "2026-08-31T12:00:00Z",
			merge_commit_sha = MERGE,
			html_url = "https://github.com/shop/world/pull/1006544",
		}))
	)
	route(
		routes,
		{ "gh", "api", "--paginate", "--slurp", "repos/shop/world/pulls/1006544/commits?per_page=100" },
		ok(json({ { { sha = OTHER }, { sha = TARGET:upper() } } }))
	)
	route(
		routes,
		{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
		ok(json({
			{
				number = 77,
				merged = false,
				title = "Open broad association",
			},
			{
				number = 88,
				merged = true,
				title = "Unrelated snapshot",
				merged_at = "2026-08-30T12:00:00Z",
				merge_commit_sha = MERGE,
			},
		}))
	)
	route(
		routes,
		{ "gs", "api", "repos/shop/world/pulls/88/commits?per_page=100", "--paginate" },
		ok(json({ { sha = OTHER } }))
	)

	local dependencies, state = harness(routes)
	require("mmp.github_commit").open("5EF9DEF", dependencies)
	state:check_routes()
	same_list(state.opened, { "https://github.com/shop/world/pull/1006544/commits/" .. TARGET }, "opened URLs")
	check(#state.notifications == 0, "successful lookup notified")
	check(#state.picks == 0, "single result used a picker")
end

local function test_github_only_canonicalization_and_fallback()
	local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
	route(routes, { "gh", "api", "repos/shop/world/commits/5EF9DEF", "--jq", ".sha" }, ok(TARGET:upper() .. "\n"))
	route(routes, {
		"gh",
		"search",
		"prs",
		TARGET,
		"--repo",
		"shop/world",
		"--merged",
		"--limit",
		"1000",
		"--json",
		"number,title,state,closedAt,url",
	}, ok("[]"))

	local dependencies, state = harness(routes)
	require("mmp.github_commit").open("5EF9DEF", dependencies)
	state:check_routes()
	same_list(state.opened, { "https://github.com/shop/world/commit/" .. TARGET }, "GitHub fallback")
	check(#state.notifications == 0, "fallback notified")
end

local function test_exact_meteorite_result()
	local routes = base_routes({ "origin\tssh://git@gitstream.shopify.io/shop/world.git (fetch)" })
	route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
	route(
		routes,
		{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
		ok(json({
			{
				number = 91,
				merged = true,
				title = "Exact Meteorite PR",
				merged_at = "2026-08-31T12:00:00Z",
				merge_commit_sha = MERGE,
			},
		}))
	)
	route(
		routes,
		{ "gs", "api", "repos/shop/world/pulls/91/commits?per_page=100", "--paginate" },
		ok(json({ { sha = TARGET } }))
	)

	local dependencies, state = harness(routes)
	require("mmp.github_commit").open("5ef9def", dependencies)
	state:check_routes()
	same_list(
		state.opened,
		{ "https://meteorite.shopify.io/repos/shop/world/pulls/91/commits/" .. TARGET },
		"Meteorite result"
	)
end

local function test_merge_sha_avoids_commit_list()
	local routes = base_routes({ "origin\tgit@gitstream.shopify.io:shop/world.git (fetch)" })
	route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
	route(
		routes,
		{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
		ok(json({
			{
				number = 92,
				merged = true,
				title = "Merge SHA match",
				merged_at = "2026-08-31T12:00:00Z",
				merge_commit_sha = TARGET:upper(),
			},
		}))
	)

	local dependencies, state = harness(routes)
	require("mmp.github_commit").open("5ef9def", dependencies)
	state:check_routes()
	same_list(
		state.opened,
		{ "https://meteorite.shopify.io/repos/shop/world/pulls/92/commits/" .. TARGET },
		"merge SHA result"
	)
end

local function multiple_routes()
	local routes = base_routes({
		"origin\tgit@gitstream.shopify.io:shop/world.git (fetch)",
		"github\thttps://github.com/shop/world.git (fetch)",
	})
	route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
	route(routes, {
		"gh",
		"search",
		"prs",
		TARGET,
		"--repo",
		"shop/world",
		"--merged",
		"--limit",
		"1000",
		"--json",
		"number,title,state,closedAt,url",
	}, ok(json({ { number = 30 }, { number = 10 } })))
	route(
		routes,
		{ "gh", "api", "repos/shop/world/pulls/30" },
		ok(json({
			number = 30,
			merged = true,
			title = "GitHub tied",
			merged_at = "2026-08-31T12:00:00Z",
			merge_commit_sha = TARGET,
		}))
	)
	route(
		routes,
		{ "gh", "api", "repos/shop/world/pulls/10" },
		ok(json({
			number = 10,
			merged = true,
			title = "GitHub oldest",
			merged_at = "2026-08-30T12:00:00Z",
			merge_commit_sha = TARGET,
		}))
	)
	route(
		routes,
		{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
		ok(json({
			{
				number = 20,
				merged = true,
				title = "Meteorite tied",
				merged_at = "2026-08-31T12:00:00Z",
				merge_commit_sha = TARGET,
			},
		}))
	)
	return routes
end

local function test_multiple_results_sort_and_selection()
	local routes = multiple_routes()
	local dependencies, state = harness(routes, function(items, on_choice)
		check(#items == 3, "picker did not receive three items")
		check(items[1].number == 10, "oldest result was not first")
		check(items[2].provider == "Meteorite", "Meteorite did not win equal-timestamp tie")
		check(items[3].provider == "GitHub", "GitHub equal-timestamp result was not last")
		on_choice({ commit_url = items[2].commit_url })
	end)
	require("mmp.github_commit").open("5ef9def", dependencies)
	state:check_routes()
	check(#state.picks == 1, "multiple results did not use one picker")
	same_list(
		state.opened,
		{ "https://meteorite.shopify.io/repos/shop/world/pulls/20/commits/" .. TARGET },
		"selected result"
	)
end

local function test_picker_cancellation()
	local routes = multiple_routes()
	local dependencies, state = harness(routes, function(_, on_choice)
		on_choice(nil)
	end)
	require("mmp.github_commit").open("5ef9def", dependencies)
	state:check_routes()
	check(#state.picks == 1, "cancellation scenario did not use picker")
	check(#state.opened == 0, "picker cancellation opened a URL")
	check(#state.notifications == 0, "picker cancellation notified")
end

local function test_default_picker_adapter()
	local routes = multiple_routes()
	local dependencies, state = harness(routes)
	dependencies.pick = nil

	local selected = false
	local previous_picker = package.loaded["mmp.github_commit_picker"]
	package.loaded["mmp.github_commit_picker"] = {
		select = function(items, on_choice)
			selected = true
			on_choice(items[1])
		end,
	}
	require("mmp.github_commit").open("5ef9def", dependencies)
	package.loaded["mmp.github_commit_picker"] = previous_picker

	state:check_routes()
	check(selected, "default picker did not use mmp.github_commit_picker")
	same_list(state.opened, { "https://github.com/shop/world/pull/10/commits/" .. TARGET }, "default picker result")
end

local function test_all_provider_absence_fallback()
	local routes = base_routes({
		"origin\tgit@gitstream.shopify.io:shop/world.git (fetch)",
		"github\tgit@github.com:shop/world.git (fetch)",
	})
	route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
	route(routes, {
		"gh",
		"search",
		"prs",
		TARGET,
		"--repo",
		"shop/world",
		"--merged",
		"--limit",
		"1000",
		"--json",
		"number,title,state,closedAt,url",
	}, ok("[]"))
	route(
		routes,
		{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
		ok("[]")
	)

	local dependencies, state = harness(routes)
	require("mmp.github_commit").open("5ef9def", dependencies)
	state:check_routes()
	same_list(state.opened, { "https://github.com/shop/world/commit/" .. TARGET }, "dual-provider fallback")
end

local function test_failures()
	do
		local dependencies, state = harness({})
		require("mmp.github_commit").open("not-a-hash", dependencies)
		state:check_routes()
		check(#state.commands == 0, "invalid hash ran a command")
		check(#state.notifications == 1, "invalid hash did not notify exactly once")
		check(state.notifications[1].message == "Invalid commit hash", "invalid hash notification was mislabeled")
		check(state.notifications[1].level == vim.log.levels.ERROR, "invalid hash notification was not an error")
		check(#state.opened == 0, "invalid hash opened a URL")
	end

	assert_failure(
		"5ef9def",
		base_routes({ "origin\tgit@gitstream.example.com:shop/world.git (fetch)" }),
		"Unsupported repository remote"
	)

	do
		local routes = {}
		route(routes, { "git", "remote", "-v" }, { code = 0, stdout = {}, stderr = "" })
		assert_failure("5ef9def", routes, "Could not read git remotes")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok("short\n"))
		assert_failure("5ef9def", routes, "Invalid canonical commit SHA")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok(TARGET .. "\n"))
		route(routes, {
			"gh",
			"search",
			"prs",
			TARGET,
			"--repo",
			"shop/world",
			"--merged",
			"--limit",
			"1000",
			"--json",
			"number,title,state,closedAt,url",
		}, failed("search failed"))
		assert_failure("5ef9def", routes, "GitHub PR search failed")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok(TARGET .. "\n"))
		route(routes, {
			"gh",
			"search",
			"prs",
			TARGET,
			"--repo",
			"shop/world",
			"--merged",
			"--limit",
			"1000",
			"--json",
			"number,title,state,closedAt,url",
		}, ok(json({ { number = 100 } })))
		route(routes, { "gh", "api", "repos/shop/world/pulls/100" }, failed("detail failed"))
		assert_failure("5ef9def", routes, "GitHub PR details failed")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok(TARGET .. "\n"))
		route(routes, {
			"gh",
			"search",
			"prs",
			TARGET,
			"--repo",
			"shop/world",
			"--merged",
			"--limit",
			"1000",
			"--json",
			"number,title,state,closedAt,url",
		}, ok(json({ { number = 100 } })))
		route(
			routes,
			{ "gh", "api", "repos/shop/world/pulls/100" },
			ok(json({
				number = 100,
				merged = true,
				title = "Needs commits",
				merged_at = "2026-08-31T12:00:00Z",
				merge_commit_sha = MERGE,
			}))
		)
		route(
			routes,
			{ "gh", "api", "--paginate", "--slurp", "repos/shop/world/pulls/100/commits?per_page=100" },
			failed("commit list failed")
		)
		assert_failure("5ef9def", routes, "GitHub PR commits failed")
	end

	do
		local routes = base_routes({ "origin\tgit@gitstream.shopify.io:shop/world.git (fetch)" })
		route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
		route(
			routes,
			{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
			failed("association failed")
		)
		assert_failure("5ef9def", routes, "Meteorite PR search failed")
	end

	do
		local routes = base_routes({ "origin\tgit@gitstream.shopify.io:shop/world.git (fetch)" })
		route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
		route(
			routes,
			{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
			ok(json({
				{
					number = 101,
					merged = true,
					title = "Needs commits",
					merged_at = "2026-08-31T12:00:00Z",
					merge_commit_sha = MERGE,
				},
			}))
		)
		route(
			routes,
			{ "gs", "api", "repos/shop/world/pulls/101/commits?per_page=100", "--paginate" },
			failed("commit list failed")
		)
		assert_failure("5ef9def", routes, "Meteorite PR commits failed")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok(TARGET .. "\n"))
		route(routes, {
			"gh",
			"search",
			"prs",
			TARGET,
			"--repo",
			"shop/world",
			"--merged",
			"--limit",
			"1000",
			"--json",
			"number,title,state,closedAt,url",
		}, ok(json({ { number = "bad" } })))
		assert_failure("5ef9def", routes, "Invalid GitHub PR candidate")
	end

	do
		local routes = base_routes({ "origin\tgit@gitstream.shopify.io:shop/world.git (fetch)" })
		route(routes, { "gs", "api", "repos/shop/world/commits/5ef9def" }, ok(json({ sha = TARGET })))
		route(
			routes,
			{ "gs", "api", "repos/shop/world/commits/" .. TARGET .. "/pulls?per_page=100", "--paginate" },
			ok(json({
				{
					number = 102,
					merged = true,
					title = "",
					merged_at = "2026-08-31T12:00:00Z",
					merge_commit_sha = TARGET,
				},
			}))
		)
		assert_failure("5ef9def", routes, "Invalid Meteorite PR candidate")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok(TARGET .. "\n"))
		route(routes, {
			"gh",
			"search",
			"prs",
			TARGET,
			"--repo",
			"shop/world",
			"--merged",
			"--limit",
			"1000",
			"--json",
			"number,title,state,closedAt,url",
		}, ok(json({ { number = 103 } })))
		route(
			routes,
			{ "gh", "api", "repos/shop/world/pulls/103" },
			ok(json({
				number = 103,
				merged = true,
				title = "Malformed commits",
				merged_at = "2026-08-31T12:00:00Z",
				merge_commit_sha = MERGE,
			}))
		)
		route(
			routes,
			{ "gh", "api", "--paginate", "--slurp", "repos/shop/world/pulls/103/commits?per_page=100" },
			ok(json({ { { sha = "bad" } } }))
		)
		assert_failure("5ef9def", routes, "Invalid GitHub PR commits response")
	end

	do
		local routes = base_routes({ "origin\thttps://github.com/shop/world.git (fetch)" })
		route(routes, { "gh", "api", "repos/shop/world/commits/5ef9def", "--jq", ".sha" }, ok(TARGET .. "\n"))
		route(routes, {
			"gh",
			"search",
			"prs",
			TARGET,
			"--repo",
			"shop/world",
			"--merged",
			"--limit",
			"1000",
			"--json",
			"number,title,state,closedAt,url",
		}, ok("not json"))
		assert_failure("5ef9def", routes, "Invalid GitHub PR search response")
	end
end

local function run()
	test_dual_remote_exact_github_result()
	test_github_only_canonicalization_and_fallback()
	test_exact_meteorite_result()
	test_merge_sha_avoids_commit_list()
	test_multiple_results_sort_and_selection()
	test_picker_cancellation()
	test_default_picker_adapter()
	test_all_provider_absence_fallback()
	test_failures()
end

local success, error_message = xpcall(run, debug.traceback)
if not success then
	io.stderr:write("github_commit_spec failure:\n" .. tostring(error_message) .. "\n")
	vim.cmd("cquit 1")
end

print("github commit resolver: ok")
vim.cmd("qa!")
