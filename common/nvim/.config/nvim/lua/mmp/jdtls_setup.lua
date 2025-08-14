local M = {}

function M.setup()
    local on_attach = function(client, bufnr)
      require'jdtls.setup'.add_commands()

      local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
      local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

      buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

      -- Mappings.
      local opts = { noremap=true, silent=true }

      buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
      buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
      buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
      buf_set_keymap('n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>', opts)
      buf_set_keymap('n', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
      buf_set_keymap('n', '<space>wa', '<Cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
      buf_set_keymap('n', '<space>wr', '<Cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
      buf_set_keymap('n', '<space>wl', '<Cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
      buf_set_keymap('n', '<space>D', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
      buf_set_keymap('n', '<space>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)
      buf_set_keymap('n', '<space>ca', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
      buf_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
      buf_set_keymap('n', '<space>e', '<Cmd>lua vim.diagnostic.open_float({scope="line"})<CR>', opts)
      buf_set_keymap('n', '[d', '<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
      buf_set_keymap('n', ']d', '<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
      buf_set_keymap('n', '<space>q', '<Cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
      buf_set_keymap("n", "<space>f", "<Cmd>lua vim.lsp.buf.format({async = true})<CR>", opts)
    end

    local root_markers = {'gradlew', 'pom.xml'}
    local root_dir = require('jdtls.setup').find_root(root_markers)
    local home = os.getenv('HOME')

    local capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true
                }
            }
        }
    }

    local workspace_folder = home .. "/.workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")
    local config = {
        flags = {
          allow_incremental_sync = true,
        };
        capabilities = capabilities,
        on_attach = on_attach,
    }

    config.settings = {
        ['java.format.settings.url'] = home .. "/.config/nvim/language-servers/java-google-formatter.xml",
        ['java.format.settings.profile'] = "GoogleStyle",
        java = {
          signatureHelp = { enabled = true };
          contentProvider = { preferred = 'fernflower' };
          completion = {
            favoriteStaticMembers = {
              "org.hamcrest.MatcherAssert.assertThat",
              "org.hamcrest.Matchers.*",
              "org.hamcrest.CoreMatchers.*",
              "org.junit.jupiter.api.Assertions.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
              "org.mockito.Mockito.*"
            }
          };
          sources = {
            organizeImports = {
              starThreshold = 9999;
              staticStarThreshold = 9999;
            };
          };
          codeGeneration = {
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
            }
          };
          configuration = {
            runtimes = {
              {
                name = "JavaSE-19",
                path = "/usr/lib/jvm/java-19-openjdk-amd64/",
              },
            }
          };
        };
    }
    config.cmd = {'java-lsp', workspace_folder}
    config.on_attach = on_attach
    config.on_init = function(client, _)
        client.notify('workspace/didChangeConfiguration', { settings = config.settings })
    end

    -- Server
    require('jdtls').start_or_attach(config)
end

return M
