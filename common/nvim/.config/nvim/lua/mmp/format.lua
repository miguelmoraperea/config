local M = {}

function M.format_file()
    local current_file = vim.fn.expand('%:p')
    if not current_file or current_file == '' then
        print('No file to format')
        return
    end

    -- Handle different file types
    if current_file:match('%.py$') then
        M.format_python_file()
    elseif current_file:match('%.json$') then
        M.format_json_file()
    else
        -- Use LSP formatting for other file types
        vim.lsp.buf.format({ async = true })
    end
end

function M.format_python_file()
    local current_file = vim.fn.expand('%:p')

    -- Save the file first
    vim.cmd('write')
    
    local cwd = vim.fn.getcwd()
    
    -- Try to find pyproject.toml in current directory or parent directories
    local function find_pyproject()
        local current_dir = vim.fn.expand('%:p:h')
        while current_dir ~= '/' do
            local pyproject_path = current_dir .. '/pyproject.toml'
            if vim.fn.filereadable(pyproject_path) == 1 then
                return current_dir
            end
            current_dir = vim.fn.fnamemodify(current_dir, ':h')
        end
        return nil
    end
    
    local project_root = find_pyproject()
    local config_arg = project_root and ('--config=' .. project_root .. '/pyproject.toml') or ''
    
    -- Run ruff check --fix first (for linting fixes) using uv tool run
    local ruff_check_cmd = string.format('uv tool run ruff@0.5.5 check --fix %s %s', config_arg, vim.fn.shellescape(current_file))
    local check_result = vim.fn.system(ruff_check_cmd)
    
    -- Run ruff format (for code formatting) using uv tool run
    local ruff_format_cmd = string.format('uv tool run ruff@0.5.5 format %s %s', config_arg, vim.fn.shellescape(current_file))
    local format_result = vim.fn.system(ruff_format_cmd)
    
    -- Reload the buffer to show changes
    vim.cmd('edit!')
    
    -- Show results
    if vim.v.shell_error == 0 then
        print('File formatted successfully')
    else
        print('Format error: ' .. (format_result or 'Unknown error'))
    end
end

function M.format_json_file()
    local current_file = vim.fn.expand('%:p')
    
    -- Save the file first
    vim.cmd('write')
    
    -- Use jq to format the JSON file
    local jq_cmd = string.format('jq . %s > %s.tmp && mv %s.tmp %s', 
        vim.fn.shellescape(current_file),
        vim.fn.shellescape(current_file),
        vim.fn.shellescape(current_file),
        vim.fn.shellescape(current_file))
    
    local result = vim.fn.system(jq_cmd)
    
    -- Reload the buffer to show changes
    vim.cmd('edit!')
    
    -- Show results
    if vim.v.shell_error == 0 then
        print('JSON file formatted successfully')
    else
        print('JSON format error: ' .. (result or 'Unknown error'))
    end
end

return M 