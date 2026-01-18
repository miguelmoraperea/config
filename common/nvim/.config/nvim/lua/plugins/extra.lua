return {
    {
        "folke/which-key.nvim",
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
                max_width = 25,
                min_width = 25,
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
