local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    {
        "folke/which-key.nvim",
    },

    {
        "folke/neodev.nvim",
        config = function()
            require("neodev").setup({
                -- add any options here, or leave empty to use the default settings
            })
        end,
    },

    {
        "EdenEast/nightfox.nvim",
        config = function()
            vim.cmd("colorscheme nightfox")
        end,
    },

    {
        "nvim-telescope/telescope.nvim",
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
                    update_cwd = true,
                    ignore_list = {},
                },
                git = {
                    enable = true,
                },
                ew = {
                    adaptive_size = false,
                    relativenumber = true,
                },
                renderer = {
                    indent_markers = {
                        enable = true,
                    },
                    highlight_git = true,
                    highlight_opened_files = "3",
                    group_empty = true,
                },
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        cmd = "TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "c", "cpp", "lua", "python", "norg", "json", "yaml", "thrift", "fish", "java" },
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
                    width = 80,
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

    {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.diagnostics.eslint,
                    null_ls.builtins.completion.spell,
                    null_ls.builtins.diagnostics.flake8,
                    null_ls.builtins.diagnostics.pycodestyle,
                    null_ls.builtins.formatting.blue,
                },
            })
        end,
    },

    {
        "nvim-neorg/neorg",
        ft = "norg",
        cmd = "Neorg",
        priority = 30,
        config = function()
            require("neorg").setup({
                load = {
                    ["core.defaults"] = {},
                    ["core.dirman"] = {
                        config = {
                            workspaces = {
                                home = "~/Desktop/git/notes/home",
                                work = "~/Desktop/git/notes/work",
                            },
                            default_workspace = "home",
                        },
                    },
                    ["core.concealer"] = {
                        folds = false,
                    },
                },
            })
        end,
    },

    {
        "mhinz/vim-signify",
        config = function()
            vim.g.signify_sign_add = ""
            vim.g.signify_sign_change = ""
            vim.g.signify_sign_delete = ""

            vim.api.nvim_set_hl(0, "SignifySignAdd", { fg = "#98c379" })
            vim.api.nvim_set_hl(0, "SignifySignDelete", { fg = "#B37130" })
            vim.api.nvim_set_hl(0, "SignifySignChange", { fg = "#B3AF43" })
        end,
    },

    {
        "sindrets/diffview.nvim",
        config = function()
            vim.keymap.set("n", "<Leader>dn", "]czz", { noremap = false })
            vim.keymap.set("n", "<Leader>dp", "[czz", { noremap = false })
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
})
