local function check(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function read_file(path)
	local file, open_error = io.open(path, "r")
	check(file ~= nil, "could not open " .. path .. ": " .. tostring(open_error))
	local content = file:read("*a")
	file:close()
	return content
end

local function run()
	local received_hash
	package.preload["mmp.github_commit"] = function()
		return {
			open = function(commit_hash)
				received_hash = commit_hash
			end,
		}
	end

	local supplied_hash = "5ef9def9bb4c7212edfa90db368b255db4d686d0"
	require("mmp.github_commit_command").setup(function()
		return supplied_hash
	end)
	vim.api.nvim_cmd({ cmd = "GithubCommitOpen" }, {})
	check(received_hash == supplied_hash, "command did not pass the exact supplied hash to the coordinator")

	local init_source = read_file(vim.fn.getcwd() .. "/lua/mmp/init.lua")
	local delegation = 'require("mmp.github_commit_command").setup(get_commit_under_cursor)'
	check(init_source:find(delegation, 1, true) ~= nil, "init.lua does not contain the exact command delegation")
end

local success, error_message = xpcall(run, debug.traceback)
if not success then
	io.stderr:write("github_commit_command_spec failure:\n" .. tostring(error_message) .. "\n")
	vim.cmd("cquit 1")
end

print("github commit command: ok")
vim.cmd("qa!")
