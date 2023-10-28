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
    buf_set_keymap("n", "<space>f", "<Cmd>lua vim.lsp.buf.format({async = true})<CR>", opts)
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
})

-- require('lspconfig').clangd.setup {
--     on_attach = on_attach,
-- }

require("lspconfig").jsonls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
})

require("lspconfig").grammarly.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "markdown", "txt", "norg" },
})

-- require'lspconfig'.java_language_server.setup{
--     on_attach = on_attach,
--     capabilities = capabilities,
--     cmd = { "java-language-server" },
-- }
--
require("lspconfig").groovyls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    -- cmd = { "groovy-language-server" },
    cmd = { "java", "-jar", "/home/mmora/.local/share/nvim/mason/packages/groovy-language-server/build/libs/groovy-language-server-all.jar" },
    root_dir = function(fname)
        return require("lspconfig").util.root_pattern("build.gradle", "settings.gradle", "gradlew")(fname)
            or require("lspconfig").util.path.dirname(fname)
    end,
    filetypes = { "groovy", "gradle" },
    settings = {
        groovy = {
            classpath = {
                -- "/home/mmora/.gradle/caches/modules-2/files-2.1",
                "/home/mmora/apps/gradle-8.3/lib",
                "/home/mmora/apps/gradle-8.3/lib/plugins",
                "/home/mmora/apps/apache-maven-3.9.3/lib",
            },
        },
    },
})

-- require'lspconfig'.kotlin_language_server.setup({
--     on_attach = on_attach,
--     capabilities = capabilities,
--     root_dir = function(fname)
--         return require'lspconfig'.util.root_pattern("settings.gradle.kts")(fname) or
--         require'lspconfig'.util.path.dirname(fname)
--     end,
-- })

-- require'lspconfig'.gradle_ls.setup{
--     on_attach = on_attach,
--     capabilities = capabilities,
--     cmd = { "gradle-language-server" },
--     root_dir = function(fname)
--         return require'lspconfig'.util.root_pattern("build.gradle", "settings.gradle", "gradlew")(fname) or
--         require'lspconfig'.util.path.dirname(fname)
--     end,
-- }
