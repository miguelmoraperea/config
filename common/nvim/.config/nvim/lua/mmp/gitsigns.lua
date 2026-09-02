local M = {}

function M.setup()
    local repo = require("gitsigns.git.repo")
    if repo.mmp_normalizes_revision_paths then
        return
    end

    -- Gitsigns looks up detected renames by relative path after passing ls-tree an absolute path.
    local ls_tree = repo.ls_tree
    repo.ls_tree = function(self, path, revision)
        local prefix = self.toplevel .. "/"
        if vim.startswith(path, prefix) then
            path = path:sub(#prefix + 1)
        end
        return ls_tree(self, path, revision)
    end
    repo.mmp_normalizes_revision_paths = true
end

return M
