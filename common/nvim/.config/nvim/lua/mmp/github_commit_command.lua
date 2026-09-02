local M = {}

function M.setup(get_commit)
	vim.api.nvim_create_user_command("GithubCommitOpen", function()
		require("mmp.github_commit").open(get_commit())
	end, {})
end

return M
