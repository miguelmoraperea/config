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
    buf_set_keymap("n", "[d", "<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
    buf_set_keymap("n", "]d", "<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
    buf_set_keymap("n", "<space>q", "<Cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
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

require("lspconfig").pyright.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        pyright = {
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
        },
        python = {
            pythonPath = "/Users/miguel/src/github.com/Shopify/merchant-analytics-etl/data-quality/lib/reportify-dq/.venv/bin/python",
            analysis = {
                extraPaths = {
                    "/Users/miguel/src/github.com/Shopify/merchant-analytics-etl/data-quality/lib/reportify-dq/src",
                    "/Users/miguel/src/github.com/Shopify/merchant-analytics-etl/data-quality/lib/reportify-dq/.venv/lib/python3.11/site-packages"
                },
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
            },
        },
    },
})

require('lspconfig').ruff_lsp.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    init_options = {
        settings = {
            -- Set line length to 100 characters to match project configuration
            ["line-length"] = 100,
            ["target-version"] = "py311",  -- Updated to match project requirements
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
