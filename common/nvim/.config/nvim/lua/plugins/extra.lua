return {
    {
        "folke/which-key.nvim",
    },

    {
        "Fildo7525/pretty_hover",
        event = "LspAttach",
        config = function(_, opts)
            require("pretty_hover").setup(opts)

            -- jdtls emits jdt:// links whose unbalanced parens break markdown
            -- link parsing (no conceal); render just the label as inline code.
            local util = require("pretty_hover.core.util")
            local orig_open_float = util.open_float
            local function strip_jdt_links(line)
                return (line:gsub("%[([^%]]-)%]%(jdt://[^%s]*%)", "`%1`"))
            end
            util.open_float = function(hover_text, format, config)
                if type(hover_text) == "string" then
                    hover_text = strip_jdt_links(hover_text)
                elseif type(hover_text) == "table" then
                    hover_text = vim.tbl_map(strip_jdt_links, hover_text)
                end
                return orig_open_float(hover_text, format, config)
            end
        end,
    },

    {
        "folke/neodev.nvim",
        config = function()
            require("neodev").setup({})
        end,
    },

    {
        "stevearc/aerial.nvim",
        opts = {
            layout = {
                max_width = 45,
                min_width = 45,
                resize_to_content = false,
                default_direction = "right",
            },
        },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<Leader>t", "<Cmd>AerialToggle<CR>" },
        },
    },

    {
        "kawre/leetcode.nvim",
        build = ":TSUpdate html",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim", -- required by telescope
            "MunifTanjim/nui.nvim",

            -- optional
            -- "nvim-treesitter/nvim-treesitter",
            -- "rcarriga/nvim-notify",
            -- "nvim-tree/nvim-web-devicons",
        },
        opts = {
            -- configuration goes here
            lang = "python3",
        },
    },
}
