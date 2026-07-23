return {
    {
        "pwntester/octo.nvim",
        cmd = "Octo",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            picker = "telescope",
            default_remote = { "github", "upstream", "origin" },
            enable_builtin = true,
            use_local_fs = false,
            reviews = {
                auto_show_threads = true,
                focus = "right",
            },
        },
        keys = {
            { "<leader>oo", "<cmd>Octo<cr>", desc = "Octo actions" },
            { "<leader>op", "<cmd>Octo pr list<cr>", desc = "Octo pull requests" },
            { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "Octo issues" },
            { "<leader>on", "<cmd>Octo notification list<cr>", desc = "Octo notifications" },
            {
                "<leader>os",
                function()
                    require("octo.utils").create_base_search_command({ include_current_repo = true })
                end,
                desc = "Octo search current repository",
            },
            { "<leader>or", "<cmd>Octo review browse<cr>", desc = "Browse PR review read-only" },
        },
    },
}
