-- Rust development plugins for reportify-rs project
-- This file configures enhanced Rust development tools

return {
  -- Enhanced Rust support with rustaceanvim
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    ft = { "rust" },
    init = function()
      -- Prevent lspconfig from automatically setting up rust-analyzer
      local ok, lspconfig = pcall(require, "lspconfig")
      if ok and lspconfig.util then
        lspconfig.util.on_setup = lspconfig.util.add_hook_before(lspconfig.util.on_setup, function(config, user_config)
          if config.name == "rust_analyzer" then
            config.autostart = false
          end
        end)
      end
    end,
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {
          -- Enable auto-completion
          autoSetHints = true,
          -- Hover actions
          hover_actions = {
            auto_focus = false,
          },
          -- Inlay hints configuration
          inlay_hints = {
            auto = true,
            show_parameter_hints = true,
            parameter_hints_prefix = "<- ",
            other_hints_prefix = "=> ",
          },
        },
        -- LSP configuration - let rustaceanvim handle rust-analyzer completely
        server = {
          on_attach = function(client, bufnr)
            -- Apply your existing on_attach from mmp.lsp
            local function buf_set_keymap(...)
              vim.api.nvim_buf_set_keymap(bufnr, ...)
            end
            local function buf_set_option(...)
              vim.api.nvim_buf_set_option(bufnr, ...)
            end

            -- Enable completion triggered by <c-x><c-o>
            buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

            -- Your existing LSP mappings
            local opts = { noremap = true, silent = true }
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
            buf_set_keymap("n", "<space>q", "<Cmd>lua vim.diagnostic.set_loclist()<CR>", opts)
            buf_set_keymap("n", "<space>f", "<Cmd>lua require('mmp.format').format_file()<CR>", opts)
            
            -- Additional Rust-specific keymaps
            local rust_opts = { buffer = bufnr, silent = true }
            vim.keymap.set("n", "<leader>dr", function()
              vim.cmd.RustLsp('debuggables')
            end, vim.tbl_extend("force", rust_opts, { desc = "Rust Debuggables" }))

            vim.keymap.set("n", "<leader>rt", function()
              vim.cmd.RustLsp('runnables')
            end, vim.tbl_extend("force", rust_opts, { desc = "Rust Runnables" }))
          end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                buildScripts = { enable = true },
              },
              completion = {
                callable = { snippets = "fill_arguments" },
              },
              procMacro = { enable = true },
              diagnostics = {
                enable = true,
                experimental = { enable = true },
              },
              check = {
                command = "clippy",
                allTargets = false,
                extraArgs = { "--all-targets", "--all-features", "--workspace", "--", "-D", "warnings" },
              },
              inlayHints = {
                bindingModeHints = { enable = false },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 25 },
                closureReturnTypeHints = { enable = "never" },
                lifetimeElisionHints = { enable = "never" },
                parameterHints = { enable = true },
                reborrowHints = { enable = "never" },
                renderColons = true,
                typeHints = { enable = true },
              },
            },
          },
        },
        -- Debugging configuration (requires nvim-dap)
        dap = {
          adapter = {
            type = "executable",
            command = "lldb-vscode",
            name = "rt_lldb",
          },
        },
      }
    end,
  },

  -- Enhanced syntax highlighting for Rust and related files
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "rust",
        "toml",
        "yaml",
        "json",
      })
      return opts
    end,
  },

  -- Crates.nvim for Cargo.toml support
  {
    "saecki/crates.nvim",
    ft = { "rust", "toml" },
    config = function()
      require("crates").setup({
        popup = {
          autofocus = true,
          hide_on_select = true,
          copy_register = '"',
          style = "minimal",
          border = "none",
          show_version_date = false,
          show_dependency_version = true,
          max_height = 30,
          min_width = 20,
          padding = 1,
        },
      })
    end,
  },
}