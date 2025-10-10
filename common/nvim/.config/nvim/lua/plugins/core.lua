return {
    {
        "EdenEast/nightfox.nvim",
        config = function()
            vim.cmd("colorscheme nightfox")
        end,
    },

    {
        "folke/zen-mode.nvim",
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-fzf-native.nvim",
            "nvim-telescope/telescope-fzy-native.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-telescope/telescope-project.nvim",
        },
        config = function()
            require("mmp.telescope")
        end,
    },

    {
        "nvim-tree/nvim-tree.lua",
        keys = {
            { "<Leader>m", "<Cmd>NvimTreeToggle<CR>" },
            { "<Leader>n", "<Cmd>NvimTreeFindFile<CR>" },
        },
        config = function()
            -- disable netrw at the very start of your init.lua (strongly advised)
            vim.g.loaded = 1
            vim.g.loaded_netrwPlugin = 1

            -- empty setup using defaults
            require("nvim-tree").setup({
                update_cwd = true,

                update_focused_file = {
                    enable = true,
                    update_cwd = false,
                    ignore_list = {},
                },
                git = {
                    enable = true,
                },
                view = {
                    adaptive_size = true,
                    relativenumber = true,
                },
                renderer = {
                    icons = {
                        show = {
                            file = false,
                            folder = false,
                            git = false,
                        },
                        glyphs = {
                            folder = {
                                arrow_closed = "-",
                            },
                        },
                    },
                    indent_markers = {
                        enable = true,
                    },
                    highlight_git = true,
                    highlight_opened_files = "all",
                    group_empty = true,
                },
                actions = {
                    change_dir = {
                        enable = true,
                        global = true,
                        restrict_above_cwd = false,
                    },
                },
                filters = {
                    dotfiles = false,
                    custom = { "__pycache__", "releases" }, -- "build$"
                    git_ignored = false,
                },
                log = {
                    enable = true,
                    truncate = true,
                    types = {
                        diagnostics = true,
                        git = true,
                        profile = true,
                        watcher = true,
                    },
                },
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        cmd = "TSUpdate",
        lazy = false,
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "c",
                    "cpp",
                    "lua",
                    "python",
                    "norg",
                    "json",
                    "yaml",
                    "thrift",
                    "fish",
                    "java",
                    "kotlin",
                    "go",
                },
                highlight = {
                    enable = true,
                },
            })
        end,
    },

    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup()
        end,
    },

    {
        "neovim/nvim-lspconfig",
    },

    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
        },
        config = function()
            require("mmp.nvim-cmp")
        end,
    },

    {
        "github/copilot.vim",
        config = function()
            vim.g.copilot_assume_mapped = true
            vim.g.copilot_no_tab_map = true
            vim.api.nvim_set_keymap("i", "<C-f>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
        end,
    },

    {
        "AckslD/messages.nvim",
        config = function()
            require("messages").setup()
        end,
    },

    {
        "ThePrimeagen/harpoon",
        config = function()
            require("harpoon").setup({
                global_settings = {
                    save_on_toggle = true,
                    enter_on_sendcmd = true,
                    tmux_autoclose_windows = true,
                },
                menu = {
                    height = 20,
                    width = 120,
                },
            })

            vim.api.nvim_set_keymap(
                "n",
                "<Leader><Backspace>",
                '<Cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>mk",
                '<Cmd>lua require("harpoon.mark").add_file()<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>0",
                '<Cmd>lua require("harpoon.ui").nav_file(0)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>1",
                '<Cmd>lua require("harpoon.ui").nav_file(1)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>2",
                '<Cmd>lua require("harpoon.ui").nav_file(2)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>3",
                '<Cmd>lua require("harpoon.ui").nav_file(3)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>4",
                '<Cmd>lua require("harpoon.ui").nav_file(4)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>5",
                '<Cmd>lua require("harpoon.ui").nav_file(5)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>6",
                '<Cmd>lua require("harpoon.ui").nav_file(6)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>7",
                '<Cmd>lua require("harpoon.ui").nav_file(7)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>8",
                '<Cmd>lua require("harpoon.ui").nav_file(8)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>9",
                '<Cmd>lua require("harpoon.ui").nav_file(9)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>10",
                '<Cmd>lua require("harpoon.ui").nav_file(10)<CR>',
                { noremap = true }
            )

            -- Terminals
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>t1",
                '<Cmd>lua require("harpoon.tmux").gotoTerminal(1)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>t2",
                '<Cmd>lua require("harpoon.tmux").gotoTerminal(2)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>t3",
                '<Cmd>lua require("harpoon.tmux").gotoTerminal(3)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>t4",
                '<Cmd>lua require("harpoon.tmux").gotoTerminal(4)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>t5",
                '<Cmd>lua require("harpoon.tmux").gotoTerminal(5)<CR>',
                { noremap = true }
            )

            -- Commands
            vim.api.nvim_set_keymap(
                "n",
                "<Leader><Backspace>c",
                '<Cmd>lua require("harpoon.cmd-ui").toggle_quick_menu()<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>c1",
                '<Cmd>lua require("harpoon.tmux").sendCommand(1, 1)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>c2",
                '<Cmd>lua require("harpoon.tmux").sendCommand(2, 2)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>c3",
                '<Cmd>lua require("harpoon.tmux").sendCommand(3, 3)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>c4",
                '<Cmd>lua require("harpoon.tmux").sendCommand(4, 4)<CR>',
                { noremap = true }
            )
            vim.api.nvim_set_keymap(
                "n",
                "<Leader>c5",
                '<Cmd>lua require("harpoon.tmux").sendCommand(5, 5)<CR>',
                { noremap = true }
            )
        end,
    },

    -- {
    --     "jose-elias-alvarez/null-ls.nvim",
    --     config = function()
    --         require("mmp.null-ls")
    --     end,
    -- },

    {
        "jay-babu/mason-null-ls.nvim",
        lazy = false,
        dependencies = {
            "williamboman/mason.nvim",
            "nvimtools/none-ls.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-null-ls").setup({
                ensure_installed = {
                    "blue",
                    "grammarly-language-server",
                    "jq",
                    -- "mypy",
                    -- "pycodestyle",
                    -- "pyright",
                    "spell",
                    "stylua",
                    -- "usort",
                    "kotlin-language-server",
                    -- "vulture",
                    -- C++ tools
                    "clangd",
                    "clang-format",
                },
                automatic_installation = false,
                handlers = {},
            })
            require("mmp.null-ls")
        end,
    },

    { "nvim-neorg/tree-sitter-norg" },

    -- {
    --     "nvim-neorg/neorg",
    --     ft = "norg",
    --     opts = {
    --       load = {
    --                 ["core.defaults"] = {},
    --                 ["core.dirman"] = {
    --                     config = {
    --                         workspaces = {
    --                             notes = "~/Desktop/git/notes",
    --                         },
    --                         default_workspace = "home",
    --                     },
    --                 },
    --                 ["core.concealer"] = {},
    --             },
    --       },
    -- },

    {
        "vhyrro/luarocks.nvim",
        priority = 1000, -- We'd like this plugin to load first out of the rest
        config = true,   -- This automatically runs `require("luarocks-nvim").setup()`
    },

    {
        "nvim-neorg/neorg",
        ft = "norg",
        cmd = "Neorg",
        priority = 30, -- treesitter is on default priority of 50, neorg should load after it.
        dependencies = { "luarocks.nvim" },
        config = function()
            require("neorg").setup({
                load = {
                    ["core.defaults"] = {},
                    ["core.dirman"] = {
                        config = {
                            workspaces = {
                                notes = "~/Desktop/git/notes",
                            },
                            default_workspace = "home",
                        },
                    },
                    ["core.concealer"] = {},
                },
            })
        end,
    },

    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup({
                toggler = {
                    line = "<Leader>c<Space>",
                    block = "<Leader>b<Space>",
                },
                opleader = {
                    line = "<Leader>c<Space>",
                    block = "<Leader>b<Space>",
                },
            })
        end,
    },

    {
        "norcalli/nvim-colorizer.lua",
        config = function()
            require("colorizer").setup()
            -- require 'colorizer'.setup(nil, { RRGGBBAA = true; })
        end,
    },

    {
        -- "viniarck/telescope-tmuxdir.nvim",
        "miguelmoraperea/telescope-tmuxdir.nvim",
        -- dir = "~/Desktop/git/telescope-tmuxdir.nvim",
        keys = {
            { "<Leader>fx", "<Cmd>Telescope tmuxdir sessions<CR>" },
            { "<Leader>fi", "<Cmd>Telescope tmuxdir dirs<CR>" },
        },
    },

    { "junegunn/gv.vim",            dependencies = { "tpope/vim-fugitive" } },

    {
        "sindrets/diffview.nvim",
        config = function()
            vim.keymap.set("n", "<Leader>dn", "]czz", { noremap = false })
            vim.keymap.set("n", "<Leader>dp", "[czz", { noremap = false })

            require("diffview").setup({
                file_panel = {
                    win_config = {
                        position = "left",
                        -- height = 20,
                        width = 50,
                    },
                },
                view = {
                    default = {
                        layout = "diff2_horizontal",
                        winbar_info = false,
                    },
                    merge_tool = {
                        layout = "diff3_horizontal",
                        disable_diagnostics = true,
                        winbar_info = true,
                    },
                    file_history = {
                        layout = "diff2_horizontal",
                        winbar_info = false,
                    },
                },
                hooks = {
                    diff_buf_read = function(bufnr)
                        -- Disable automatic fold opening in diffview buffers
                        vim.api.nvim_buf_set_option(bufnr, 'foldopen', '')
                        vim.api.nvim_buf_set_option(bufnr, 'foldenable', true)
                    end,
                },
            })
        end,
    },

    {
        "MunifTanjim/nui.nvim",
    },

    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require('gitsigns').setup({
                -- signs                        = {
                --     add          = { text = '┃' },
                --     change       = { text = '┃' },
                --     delete       = { text = '_' },
                --     topdelete    = { text = '‾' },
                --     changedelete = { text = '~' },
                --     untracked    = { text = '┆' },
                -- },
                signs_staged                 = {
                    add          = { text = '┃' },
                    change       = { text = '┃' },
                    delete       = { text = '_' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                    untracked    = { text = '┆' },
                },
                signs_staged_enable          = true,
                signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
                numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
                linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
                word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
                watch_gitdir                 = {
                    follow_files = true
                },
                auto_attach                  = true,
                attach_to_untracked          = false,
                current_line_blame           = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
                current_line_blame_opts      = {
                    virt_text = true,
                    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                    delay = 1000,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                    use_focus = true,
                },
                current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
                sign_priority                = 6,
                update_debounce              = 100,
                status_formatter             = nil,   -- Use default
                max_file_length              = 40000, -- Disable if file is longer than this (in lines)
                preview_config               = {
                    -- Options passed to nvim_open_win
                    border = 'single',
                    style = 'minimal',
                    relative = 'cursor',
                    row = 0,
                    col = 1
                },
                on_attach                    = function(bufnr)
                    local gitsigns = require('gitsigns')

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map('n', '{c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ '{c', bang = true })
                        else
                            gitsigns.nav_hunk('next')
                        end
                    end)

                    map('n', '(c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ '(c', bang = true })
                        else
                            gitsigns.nav_hunk('prev')
                        end
                    end)

                    -- Actions
                    map('n', '<leader>hs', gitsigns.stage_hunk)
                    map('n', '<leader>hr', gitsigns.reset_hunk)

                    map('v', '<leader>hs', function()
                        gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
                    end)

                    map('v', '<leader>hr', function()
                        gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
                    end)

                    map('n', '<leader>hS', gitsigns.stage_buffer)
                    map('n', '<leader>hR', gitsigns.reset_buffer)
                    map('n', '<leader>hp', gitsigns.preview_hunk)
                    map('n', '<leader>hi', gitsigns.preview_hunk_inline)

                    map('n', '<leader>hb', function()
                        gitsigns.blame_line({ full = true })
                    end)

                    map('n', '<leader>hd', gitsigns.diffthis)

                    map('n', '<leader>hD', function()
                        gitsigns.diffthis('~')
                    end)

                    map('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
                    map('n', '<leader>hq', gitsigns.setqflist)

                    -- Toggles
                    map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
                    map('n', '<leader>tw', gitsigns.toggle_word_diff)

                    -- Text object
                    map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
                end
            })
        end,
    },
}
