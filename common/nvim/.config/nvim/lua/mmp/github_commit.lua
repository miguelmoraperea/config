local M = {}

local function default_run(command, callback)
	vim.system(command, { text = true }, function(result)
		vim.schedule(function()
			callback(result)
		end)
	end)
end

local function default_open(url)
	vim.fn.jobstart({ "open", "-a", "Google Chrome", "-n", "--args", url }, { detach = true })
end

local function default_notify(message)
	vim.notify(message, vim.log.levels.ERROR)
end

local function default_pick(items, on_choice)
	require("mmp.github_commit_picker").select(items, on_choice)
end

local function is_hash(value, minimum, maximum)
	return type(value) == "string" and #value >= minimum and #value <= maximum and value:match("^%x+$") ~= nil
end

local function is_sha(value)
	return is_hash(value, 40, 40)
end

local function is_positive_integer(value)
	return type(value) == "number" and value > 0 and value % 1 == 0
end

local function is_nonempty_string(value)
	return type(value) == "string" and value ~= ""
end

local function is_null(value)
	return value == nil or value == vim.NIL
end

local function decode_json(raw)
	if type(raw) ~= "string" then
		return nil
	end
	local success, value = pcall(vim.json.decode, raw)
	if not success then
		return nil
	end
	return value
end

local function decode_array(raw)
	if type(raw) ~= "string" or not raw:match("^%s*%[") then
		return nil
	end
	local value = decode_json(raw)
	if type(value) ~= "table" or not vim.islist(value) then
		return nil
	end
	return value
end

local function decode_object(raw)
	if type(raw) ~= "string" or not raw:match("^%s*{") then
		return nil
	end
	local value = decode_json(raw)
	if type(value) ~= "table" or vim.islist(value) then
		return nil
	end
	return value
end

local function parse_remote_url(url)
	local host
	local path
	local scheme, remainder = url:match("^([%a][%w+.-]*)://(.+)$")
	if scheme then
		scheme = scheme:lower()
		if scheme ~= "ssh" and scheme ~= "http" and scheme ~= "https" then
			return nil
		end
		local authority
		authority, path = remainder:match("^([^/]+)/(.+)$")
		if not authority then
			return nil
		end
		host = authority:match("@([^@]+)$") or authority
		host = host:gsub(":%d+$", "")
	else
		host, path = url:match("^[^@%s]+@([^:%s]+):(.+)$")
		if not host then
			return nil
		end
	end

	path = path:gsub("[?#].*$", ""):gsub("^/+", ""):gsub("/+$", ""):gsub("%.git$", "")
	local owner, repository = path:match("^([^/]+)/([^/]+)$")
	if not owner or not repository or owner == "" or repository == "" then
		return nil
	end

	return {
		host = host:lower(),
		owner = owner,
		repository = repository,
	}
end

local function remote_priority(provider, name)
	if provider == "github" then
		local priorities = { github = 1, upstream = 2, origin = 3 }
		return priorities[name] or 4
	end
	return name == "origin" and 1 or 2
end

local function discover_remotes(output)
	local selected = {}
	local order = 0

	for line in output:gmatch("[^\r\n]+") do
		local name, url = line:match("^(%S+)%s+(%S+)%s+%(fetch%)%s*$")
		if name and url then
			local parsed = parse_remote_url(url)
			if parsed then
				local provider
				if parsed.host == "github.com" then
					provider = "github"
				elseif parsed.host == "gitstream.shopify.io" then
					provider = "gitstream"
				end

				if provider then
					order = order + 1
					parsed.name = name
					parsed.priority = remote_priority(provider, name)
					parsed.order = order
					local current = selected[provider]
					if
						not current
						or parsed.priority < current.priority
						or (parsed.priority == current.priority and parsed.order < current.order)
					then
						selected[provider] = parsed
					end
				end
			end
		end
	end

	return selected.github, selected.gitstream
end

local function validate_merge_sha(value)
	if is_null(value) then
		return true, nil
	end
	if not is_sha(value) then
		return false
	end
	return true, value:lower()
end

local function validate_merged_metadata(candidate)
	if not is_nonempty_string(candidate.title) or not is_nonempty_string(candidate.merged_at) then
		return false
	end
	local valid_sha, merge_sha = validate_merge_sha(candidate.merge_commit_sha)
	if not valid_sha then
		return false
	end
	return true, merge_sha
end

local function github_result(repository, candidate, sha)
	local url =
		string.format("https://github.com/%s/%s/pull/%d", repository.owner, repository.repository, candidate.number)
	return {
		provider = "GitHub",
		number = candidate.number,
		title = candidate.title,
		merged_at = candidate.merged_at,
		url = url,
		commit_url = url .. "/commits/" .. sha,
	}
end

local function meteorite_result(repository, candidate, sha)
	local url = string.format(
		"https://meteorite.shopify.io/repos/%s/%s/pulls/%d",
		repository.owner,
		repository.repository,
		candidate.number
	)
	return {
		provider = "Meteorite",
		number = candidate.number,
		title = candidate.title,
		merged_at = candidate.merged_at,
		url = url,
		commit_url = url .. "/commits/" .. sha,
	}
end

local function sort_and_deduplicate(results)
	local deduplicated = {}
	local seen = {}
	for _, result in ipairs(results) do
		if not seen[result.url] then
			seen[result.url] = true
			table.insert(deduplicated, result)
		end
	end

	local provider_order = { Meteorite = 1, GitHub = 2 }
	table.sort(deduplicated, function(left, right)
		if left.merged_at ~= right.merged_at then
			return left.merged_at < right.merged_at
		end
		if left.provider ~= right.provider then
			return provider_order[left.provider] < provider_order[right.provider]
		end
		return left.number < right.number
	end)
	return deduplicated
end

function M.open(raw_hash, dependencies)
	dependencies = dependencies or {}
	local run_command = dependencies.run or default_run
	local open_url = dependencies.open or default_open
	local notify = dependencies.notify or default_notify
	local pick = dependencies.pick or default_pick
	local state = { terminal = false, presenting = false }

	local function fail(message)
		if state.terminal or state.presenting then
			return
		end
		state.terminal = true
		notify(message, vim.log.levels.ERROR)
	end

	local function invoke(command, message, callback)
		if state.terminal or state.presenting then
			return
		end
		local settled = false
		local success = pcall(run_command, command, function(result)
			if settled or state.terminal or state.presenting then
				return
			end
			settled = true
			if
				type(result) ~= "table"
				or type(result.code) ~= "number"
				or result.code ~= 0
				or (result.stdout ~= nil and type(result.stdout) ~= "string")
			then
				fail(message)
				return
			end
			local callback_success = pcall(callback, result.stdout or "")
			if not callback_success then
				fail(message)
			end
		end)
		if not success and not settled then
			settled = true
			fail(message)
		end
	end

	local function present(results, fallback_repository, sha)
		if state.terminal or state.presenting then
			return
		end
		results = sort_and_deduplicate(results)
		if #results == 0 then
			state.terminal = true
			open_url(
				string.format(
					"https://github.com/%s/%s/commit/%s",
					fallback_repository.owner,
					fallback_repository.repository,
					sha
				)
			)
			return
		end
		if #results == 1 then
			state.terminal = true
			open_url(results[1].commit_url)
			return
		end

		state.presenting = true
		local choice_made = false
		local success = pcall(pick, results, function(choice)
			if choice_made or state.terminal then
				return
			end
			choice_made = true
			state.presenting = false
			state.terminal = true
			if choice ~= nil and type(choice) == "table" and is_nonempty_string(choice.commit_url) then
				open_url(choice.commit_url)
			end
		end)
		if not success and not choice_made then
			state.presenting = false
			fail("Could not show merged PRs")
		end
	end

	local function query_github(repository, sha, results, done)
		local repo = repository.owner .. "/" .. repository.repository
		invoke(
			{
				"gh",
				"search",
				"prs",
				sha,
				"--repo",
				repo,
				"--merged",
				"--limit",
				"1000",
				"--json",
				"number,title,state,closedAt,url",
			},
			"GitHub PR search failed",
			function(output)
				local candidates = decode_array(output)
				if not candidates then
					fail("Invalid GitHub PR search response")
					return
				end

				local index = 1
				local function next_candidate()
					if state.terminal then
						return
					end
					local search_candidate = candidates[index]
					if not search_candidate then
						done()
						return
					end
					index = index + 1
					if type(search_candidate) ~= "table" or not is_positive_integer(search_candidate.number) then
						fail("Invalid GitHub PR candidate")
						return
					end

					local requested_number = search_candidate.number
					invoke(
						{ "gh", "api", string.format("repos/%s/pulls/%d", repo, requested_number) },
						"GitHub PR details failed",
						function(detail_output)
							local detail = decode_object(detail_output)
							if
								not detail
								or not is_positive_integer(detail.number)
								or detail.number ~= requested_number
								or type(detail.merged) ~= "boolean"
							then
								fail("Invalid GitHub PR details")
								return
							end
							if not detail.merged then
								next_candidate()
								return
							end

							local valid_metadata, merge_sha = validate_merged_metadata(detail)
							if not valid_metadata then
								fail("Invalid GitHub PR details")
								return
							end
							if merge_sha == sha then
								table.insert(results, github_result(repository, detail, sha))
								next_candidate()
								return
							end

							invoke(
								{
									"gh",
									"api",
									"--paginate",
									"--slurp",
									string.format("repos/%s/pulls/%d/commits?per_page=100", repo, detail.number),
								},
								"GitHub PR commits failed",
								function(commits_output)
									local pages = decode_array(commits_output)
									if not pages then
										fail("Invalid GitHub PR commits response")
										return
									end

									local matches = false
									for _, page in ipairs(pages) do
										if type(page) ~= "table" or not vim.islist(page) then
											fail("Invalid GitHub PR commits response")
											return
										end
										for _, commit in ipairs(page) do
											if type(commit) ~= "table" or not is_sha(commit.sha) then
												fail("Invalid GitHub PR commits response")
												return
											end
											if commit.sha:lower() == sha then
												matches = true
											end
										end
									end
									if matches then
										table.insert(results, github_result(repository, detail, sha))
									end
									next_candidate()
								end
							)
						end
					)
				end

				next_candidate()
			end
		)
	end

	local function query_meteorite(repository, sha, results, done)
		local repo = repository.owner .. "/" .. repository.repository
		invoke(
			{
				"gs",
				"api",
				string.format("repos/%s/commits/%s/pulls?per_page=100", repo, sha),
				"--paginate",
			},
			"Meteorite PR search failed",
			function(output)
				local candidates = decode_array(output)
				if not candidates then
					fail("Invalid Meteorite PR search response")
					return
				end

				local index = 1
				local function next_candidate()
					if state.terminal then
						return
					end
					local candidate = candidates[index]
					if not candidate then
						done()
						return
					end
					index = index + 1
					if
						type(candidate) ~= "table"
						or not is_positive_integer(candidate.number)
						or type(candidate.merged) ~= "boolean"
					then
						fail("Invalid Meteorite PR candidate")
						return
					end
					if not candidate.merged then
						next_candidate()
						return
					end

					local valid_metadata, merge_sha = validate_merged_metadata(candidate)
					if not valid_metadata then
						fail("Invalid Meteorite PR candidate")
						return
					end
					if merge_sha == sha then
						table.insert(results, meteorite_result(repository, candidate, sha))
						next_candidate()
						return
					end

					invoke(
						{
							"gs",
							"api",
							string.format("repos/%s/pulls/%d/commits?per_page=100", repo, candidate.number),
							"--paginate",
						},
						"Meteorite PR commits failed",
						function(commits_output)
							local commits = decode_array(commits_output)
							if not commits then
								fail("Invalid Meteorite PR commits response")
								return
							end

							local matches = false
							for _, commit in ipairs(commits) do
								if type(commit) ~= "table" or not is_sha(commit.sha) then
									fail("Invalid Meteorite PR commits response")
									return
								end
								if commit.sha:lower() == sha then
									matches = true
								end
							end
							if matches then
								table.insert(results, meteorite_result(repository, candidate, sha))
							end
							next_candidate()
						end
					)
				end

				next_candidate()
			end
		)
	end

	local function resolve_sha(github, gitstream, callback)
		local repository = gitstream or github
		local repo = repository.owner .. "/" .. repository.repository
		if gitstream then
			invoke(
				{ "gs", "api", string.format("repos/%s/commits/%s", repo, raw_hash) },
				"Commit lookup failed",
				function(output)
					local response = decode_object(output)
					if not response or not is_sha(response.sha) then
						fail("Invalid canonical commit SHA")
						return
					end
					callback(response.sha:lower())
				end
			)
			return
		end

		invoke(
			{ "gh", "api", string.format("repos/%s/commits/%s", repo, raw_hash), "--jq", ".sha" },
			"Commit lookup failed",
			function(output)
				local sha = vim.trim(output)
				if not is_sha(sha) then
					fail("Invalid canonical commit SHA")
					return
				end
				callback(sha:lower())
			end
		)
	end

	if not is_hash(raw_hash, 7, 40) then
		fail("Invalid commit hash")
		return
	end

	invoke({ "git", "remote", "-v" }, "Could not read git remotes", function(output)
		local github, gitstream = discover_remotes(output)
		if not github and not gitstream then
			fail("Unsupported repository remote")
			return
		end

		resolve_sha(github, gitstream, function(sha)
			local results = {}
			local function query_meteorite_after_github()
				if gitstream then
					query_meteorite(gitstream, sha, results, function()
						present(results, github or gitstream, sha)
					end)
				else
					present(results, github, sha)
				end
			end

			if github then
				query_github(github, sha, results, query_meteorite_after_github)
			else
				query_meteorite_after_github()
			end
		end)
	end)
end

return M
