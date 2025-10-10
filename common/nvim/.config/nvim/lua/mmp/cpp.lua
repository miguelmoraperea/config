local M = {}

-- C++ specific configuration for reportify-cpp project
M.setup = function()
    -- Project-specific path
    local project_path = "/Users/miguel/src/github.com/Shopify/merchant-analytics-etl/reportify-next/reportify-cpp"
    
    -- Auto-format C++ files on save (only in reportify-cpp project)
    vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = {"*.cpp", "*.hpp", "*.c", "*.h"},
        callback = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            if string.match(bufname, "reportify%-cpp") then
                vim.lsp.buf.format({ async = false })
            end
        end,
    })

    -- Set C++ specific settings for reportify-cpp project
    vim.api.nvim_create_autocmd("FileType", {
        pattern = {"cpp", "c"},
        callback = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            if string.match(bufname, "reportify%-cpp") then
                -- Set project-specific settings
                vim.opt_local.textwidth = 100
                vim.opt_local.colorcolumn = "100"
                vim.opt_local.tabstop = 4
                vim.opt_local.shiftwidth = 4
                vim.opt_local.expandtab = true
                vim.opt_local.cindent = true
                
                -- C++ specific indentation
                vim.opt_local.cinoptions = "g0,N-s,i0,+0"
            end
        end,
    })

    -- Project-specific build commands
    local function create_cpp_commands()
        -- Build command
        vim.api.nvim_create_user_command("CppBuild", function(opts)
            local build_type = opts.args ~= "" and opts.args or "Debug"
            local cmd = string.format("cd %s && cmake --build build --config %s", project_path, build_type)
            vim.cmd("!" .. cmd)
        end, { nargs = '?' })

        -- Clean build command
        vim.api.nvim_create_user_command("CppClean", function()
            local cmd = string.format("cd %s && rm -rf build && mkdir build", project_path)
            vim.cmd("!" .. cmd)
        end, {})

        -- Configure build command
        vim.api.nvim_create_user_command("CppConfigure", function(opts)
            local build_type = opts.args ~= "" and opts.args or "Debug"
            local cmd = string.format("cd %s && cmake -B build -DCMAKE_BUILD_TYPE=%s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON", project_path, build_type)
            vim.cmd("!" .. cmd)
        end, { nargs = '?' })

        -- Test command
        vim.api.nvim_create_user_command("CppTest", function()
            local cmd = string.format("cd %s && cd build && ctest --output-on-failure", project_path)
            vim.cmd("!" .. cmd)
        end, {})

        -- Format code command
        vim.api.nvim_create_user_command("CppFormat", function()
            local cmd = string.format("cd %s && find src include tests -name '*.cpp' -o -name '*.hpp' | xargs clang-format -i", project_path)
            vim.cmd("!" .. cmd)
        end, {})

        -- Lint code command
        vim.api.nvim_create_user_command("CppLint", function()
            local cmd = string.format("cd %s && find src include tests -name '*.cpp' -o -name '*.hpp' | xargs clang-tidy", project_path)
            vim.cmd("!" .. cmd)
        end, {})

        -- Run the main executable
        vim.api.nvim_create_user_command("CppRun", function(opts)
            local args = opts.args ~= "" and " " .. opts.args or ""
            local cmd = string.format("cd %s && ./build/reportify-cpp%s", project_path, args)
            vim.cmd("!" .. cmd)
        end, { nargs = '*' })

        -- Restart clangd to force reindexing
        vim.api.nvim_create_user_command("CppRestartLsp", function()
            vim.cmd("LspRestart clangd")
            print("Restarted clangd LSP server")
        end, {})
    end

    create_cpp_commands()

    -- Keymaps for C++ development (only in reportify-cpp project)
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            if string.match(bufname, "reportify%-cpp") then
                -- Build and run keymaps
                vim.keymap.set("n", "<leader>cb", ":CppBuild<CR>", { buffer = true, desc = "Build C++ project" })
                vim.keymap.set("n", "<leader>cr", ":CppRun<CR>", { buffer = true, desc = "Run C++ executable" })
                vim.keymap.set("n", "<leader>ct", ":CppTest<CR>", { buffer = true, desc = "Run C++ tests" })
                vim.keymap.set("n", "<leader>cc", ":CppConfigure<CR>", { buffer = true, desc = "Configure C++ project" })
                vim.keymap.set("n", "<leader>cf", ":CppFormat<CR>", { buffer = true, desc = "Format C++ code" })
                vim.keymap.set("n", "<leader>cl", ":CppLint<CR>", { buffer = true, desc = "Lint C++ code" })
                vim.keymap.set("n", "<leader>cx", ":CppRestartLsp<CR>", { buffer = true, desc = "Restart clangd LSP" })
                
                -- Quick navigation between header and source files
                vim.keymap.set("n", "gh", ":ClangdSwitchSourceHeader<CR>", { buffer = true, desc = "Switch between header/source" })
            end
        end,
    })

    -- Set up compile_commands.json integration
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            local compile_commands = project_path .. "/build/compile_commands.json"
            if vim.fn.filereadable(compile_commands) == 1 then
                print("Found compile_commands.json for reportify-cpp project")
            end
        end,
    })
end

return M
