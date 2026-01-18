-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    --Enable completion triggered by <c-x><c-o>
    buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings.
    local opts = { noremap = true, silent = true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    buf_set_keymap("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
    buf_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
    buf_set_keymap("n", "gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    buf_set_keymap("n", "<C-k>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    buf_set_keymap("n", "<space>wa", "<Cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
    buf_set_keymap("n", "<space>wr", "<Cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
    buf_set_keymap("n", "<space>wl", "<Cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
    buf_set_keymap("n", "<space>D", "<Cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
    buf_set_keymap("n", "<space>rn", "<Cmd>lua vim.lsp.buf.rename()<CR>", opts)
    buf_set_keymap("n", "<space>ca", "<Cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    buf_set_keymap("n", "gr", "<Cmd>lua vim.lsp.buf.references()<CR>", opts)
    buf_set_keymap("n", "<space>e", '<Cmd>lua vim.diagnostic.open_float({scope="line"})<CR>', opts)
    buf_set_keymap("n", "[d", "<Cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
    buf_set_keymap("n", "]d", "<Cmd>lua vim.diagnostic.goto_next()<CR>", opts)
    buf_set_keymap("n", "<space>q", "<Cmd>lua vim.diagnostic.setloclist()<CR>", opts)
    -- Custom formatting that uses project's ruff configuration
    buf_set_keymap("n", "<space>f", "<Cmd>lua require('mmp.format').format_file()<CR>", opts)
end

local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

require("lspconfig").lua_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = "LuaJIT",
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { "vim" },
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },
        },
    },
})

-- Simple function to check if a directory is a uv project
local function is_uv_project(workspace)
    return vim.fn.filereadable(workspace .. '/uv.lock') == 1 or
           vim.fn.filereadable(workspace .. '/pyproject.toml') == 1
end

-- Simple function to get Python path for uv projects
local function get_python_path(workspace)
    local venv_python = workspace .. '/.venv/bin/python'
    if vim.fn.filereadable(venv_python) == 1 then
        return venv_python
    end
    return vim.fn.exepath('python3') or 'python3'
end


require('lspconfig').ruff_lsp.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    root_dir = function(fname)
        local util = require("lspconfig.util")
        
        -- First, check if we're in a nested python directory structure
        local current_dir = vim.fn.fnamemodify(fname, ':h')
        while current_dir ~= '/' do
            -- Check if current directory has uv.lock and pyproject.toml (uv project)
            if vim.fn.filereadable(current_dir .. '/uv.lock') == 1 and 
               vim.fn.filereadable(current_dir .. '/pyproject.toml') == 1 then
                return current_dir
            end
            
            -- Check if parent has python subdirectory with uv project
            local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
            local python_subdir = parent_dir .. '/python'
            if vim.fn.filereadable(python_subdir .. '/uv.lock') == 1 and 
               vim.fn.filereadable(python_subdir .. '/pyproject.toml') == 1 and
               string.find(fname, python_subdir, 1, true) then
                return python_subdir
            end
            
            current_dir = parent_dir
        end
        
        -- Fall back to standard pattern matching
        local uv_root = util.root_pattern("uv.lock", "pyproject.toml")(fname)
        if uv_root then
            return uv_root
        end
        
        return util.root_pattern("setup.py", "setup.cfg", "requirements.txt", ".git")(fname)
    end,
    on_new_config = function(config, root_dir)
        -- Set environment for ruff to use the virtual environment
        config.cmd_env = config.cmd_env or {}
        if is_uv_project(root_dir) then
            local venv_path = root_dir .. '/.venv'
            if vim.fn.isdirectory(venv_path) == 1 then
                config.cmd_env.VIRTUAL_ENV = venv_path
                config.cmd_env.PATH = venv_path .. '/bin:' .. (vim.env.PATH or '')
            end
            
            -- For projects with python subdirectory, check there too
            local python_venv = root_dir .. '/python/.venv'
            if vim.fn.isdirectory(python_venv) == 1 then
                config.cmd_env.VIRTUAL_ENV = python_venv
                config.cmd_env.PATH = python_venv .. '/bin:' .. (vim.env.PATH or '')
            end
        end
    end,
    init_options = {
        settings = {
            -- Enable comprehensive linting
            select = {"E", "F", "W", "I"},
            -- Allow all fixes except for aggressive ones
            fixable = {"E", "F", "W", "I"},
            ["dummy-variable-rgx"] = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$",
            mccabe = {
                ["max-complexity"] = 10
            },
            -- Use ruff for import sorting
            isort = {
                ["skip"] = false
            }
        }
    }
})

-- Pyright setup for uv projects
require("lspconfig").pyright.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "pyright-langserver", "--stdio" },
    root_dir = function(fname)
        local util = require("lspconfig.util")
        
        -- First, check if we're in a nested python directory structure
        local current_dir = vim.fn.fnamemodify(fname, ':h')
        while current_dir ~= '/' do
            -- Check if current directory has uv.lock and pyproject.toml (uv project)
            if vim.fn.filereadable(current_dir .. '/uv.lock') == 1 and 
               vim.fn.filereadable(current_dir .. '/pyproject.toml') == 1 then
                return current_dir
            end
            
            -- Check if parent has python subdirectory with uv project
            local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
            local python_subdir = parent_dir .. '/python'
            if vim.fn.filereadable(python_subdir .. '/uv.lock') == 1 and 
               vim.fn.filereadable(python_subdir .. '/pyproject.toml') == 1 and
               string.find(fname, python_subdir, 1, true) then
                return python_subdir
            end
            
            current_dir = parent_dir
        end
        
        -- Fall back to standard pattern matching
        local uv_root = util.root_pattern("uv.lock", "pyproject.toml")(fname)
        if uv_root then
            return uv_root
        end
        
        return util.root_pattern("setup.py", "setup.cfg", "requirements.txt", ".git")(fname)
    end,
    single_file_support = false,
    on_new_config = function(config, root_dir)
        local python_path = get_python_path(root_dir)
        config.settings = config.settings or {}
        config.settings.python = config.settings.python or {}
        config.settings.python.pythonPath = python_path
        
        -- Set up environment variables for the LSP process
        config.cmd_env = config.cmd_env or {}
        if is_uv_project(root_dir) then
            local venv_path = root_dir .. '/.venv'
            if vim.fn.isdirectory(venv_path) == 1 then
                config.cmd_env.VIRTUAL_ENV = venv_path
                config.cmd_env.PATH = venv_path .. '/bin:' .. (vim.env.PATH or '')
                
                -- Set up Pyright analysis settings
                config.settings.python.analysis = config.settings.python.analysis or {}
                
                -- Explicitly set PYTHONPATH to include site-packages
                local site_packages = venv_path .. '/lib/python3.12/site-packages'
                local src_path = root_dir .. '/src'
                local extra_paths = {}
                
                if vim.fn.isdirectory(site_packages) == 1 then
                    table.insert(extra_paths, site_packages)
                end
                if vim.fn.isdirectory(src_path) == 1 then
                    table.insert(extra_paths, src_path)
                end
                
                if #extra_paths > 0 then
                    config.cmd_env.PYTHONPATH = table.concat(extra_paths, ':')
                    -- Also set in Pyright analysis settings
                    config.settings.python.analysis.extraPaths = extra_paths
                end
                
                -- Additional Pyright settings
                config.settings.python.analysis.autoSearchPaths = true
                config.settings.python.analysis.useLibraryCodeForTypes = true
                config.settings.python.analysis.typeCheckingMode = "basic"
            end
        end
    end,
    settings = {
        pyright = {
            disableOrganizeImports = true, -- Using ruff for this
        },
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
            },
        },
    },
})

require("lspconfig").gopls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
})

require("lspconfig").jsonls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        json = {
            validate = { enable = true },
        },
    },
})

require("lspconfig").grammarly.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "markdown", "txt", "norg" },
})

-- Clangd LSP for C++ development
require("lspconfig").clangd.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
        "--pch-storage=memory",
        "--all-scopes-completion",
        "--cross-file-rename",
        "--log=verbose",
        "--pretty",
        "--enable-config",
    },
    init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
        fallbackFlags = { "-std=c++20" },
    },
    root_dir = function(fname)
        local util = require("lspconfig.util")
        -- First try to find compile_commands.json or .clangd
        local root = util.root_pattern("compile_commands.json", ".clangd")(fname)
        if root then
            return root
        end
        -- Fall back to CMakeLists.txt or Makefile
        return util.root_pattern("CMakeLists.txt", "Makefile")(fname)
            or util.find_git_ancestor(fname)
            or util.path.dirname(fname)
    end,
    settings = {
        clangd = {
            -- Enable compile_commands.json detection
            compilationDatabasePath = "build",
            -- Improve indexing
            index = {
                threads = 0, -- Use all available threads
            },
        },
    },
})

-- Python LSP Server (pylsp) with mypy plugin
require("lspconfig").pylsp.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = function()
        -- Use pylsp from the virtual environment
        local util = require("lspconfig.util")
        local root_dir = util.root_pattern("uv.lock", "pyproject.toml")(vim.fn.expand('%:p'))
        if root_dir then
            local venv_pylsp = root_dir .. '/.venv/bin/pylsp'
            if vim.fn.executable(venv_pylsp) == 1 then
                return { venv_pylsp }
            end
        end
        return { "pylsp" }
    end,
    root_dir = function(fname)
        local util = require("lspconfig.util")
        
        -- Use the same root detection logic as other Python LSPs
        local current_dir = vim.fn.fnamemodify(fname, ':h')
        while current_dir ~= '/' do
            if vim.fn.filereadable(current_dir .. '/uv.lock') == 1 and 
               vim.fn.filereadable(current_dir .. '/pyproject.toml') == 1 then
                return current_dir
            end
            
            local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
            local python_subdir = parent_dir .. '/python'
            if vim.fn.filereadable(python_subdir .. '/uv.lock') == 1 and 
               vim.fn.filereadable(python_subdir .. '/pyproject.toml') == 1 and
               string.find(fname, python_subdir, 1, true) then
                return python_subdir
            end
            
            current_dir = parent_dir
        end
        
        local uv_root = util.root_pattern("uv.lock", "pyproject.toml")(fname)
        if uv_root then
            return uv_root
        end
        
        return util.root_pattern("setup.py", "setup.cfg", "requirements.txt", ".git")(fname)
    end,
    settings = {
        pylsp = {
            plugins = {
                -- Disable conflicting plugins since we're using ruff_lsp and Pyright
                pycodestyle = { enabled = false },
                mccabe = { enabled = false },
                pyflakes = { enabled = false },
                flake8 = { enabled = false },
                autopep8 = { enabled = false },
                yapf = { enabled = false },
                
                -- Disable Jedi features to avoid conflicts with Pyright
                jedi_completion = { enabled = false },
                jedi_hover = { enabled = false },
                jedi_references = { enabled = false },
                jedi_signature_help = { enabled = false },
                jedi_symbols = { enabled = false },
                
                -- Enable ONLY mypy
                pylsp_mypy = { 
                    enabled = true,
                    live_mode = false,  -- Don't run on every keystroke
                    strict = false,
                    config_sub_paths = {"mypy.ini"},  -- Use our custom config
                },
            }
        }
    }
})

