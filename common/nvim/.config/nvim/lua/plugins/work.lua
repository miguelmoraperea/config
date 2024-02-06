# If username is "mmora" then return the following plugins
if vim.fn.expand("$USER") ~= "mmora" then
    return {}
end

return {
    {
        "iamcco/markdown-preview.nvim",
        -- run = "cd app && yarn install",
        -- run = function() vim.fn["mkdp#util#install"]() end,
    },

    -- {
    --     "rcarriga/nvim-notify",
    --     lazy = false,
    --     config = function()
    --         -- vim.notify = require("notify")
    --         vim.notify = require("notify").setup({
    --             background_colour = "#000000",
    --         })
    --         -- vim.notify = require("notify").setup({
    --         --     stages = "fade_in_slide_out",
    --         --     timeout = 5000,
    --         --     background_colour = "#1e222a",
    --         --     icons = {
    --         --         ERROR = "",
    --         --         WARN = "",
    --         --         INFO = "",
    --         --         DEBUG = "",
    --         --         TRACE = "✎",
    --         --     },
    --         -- })
    --     end,
    -- },

    -- {
    --     dir = "~/Desktop/git/perforce.nvim",
    --     dependencies = { "rcarriga/nvim-notify", "nvim-lua/plenary.nvim" },
    --     config = function()
    --         require("perforce").setup({
    --             -- client = "mmora_linux_tools",
    --             client = "mmora_linux_gradle",
    --         })
    --     end,
    -- },

    -- {
    --     url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    --     ft = { "python", "cpp", "java", "groovy" },
    --     dependencies = {
    --         "mfussenegger/nvim-jdtls",
    --         "williamboman/mason.nvim",
    --     },
    --     config = function()
    --         local sonar_language_server_path =
    --         require("mason-registry").get_package("sonarlint-language-server"):get_install_path()
    --         local analyzers_path = sonar_language_server_path .. "/extension/analyzers"
    --         require("sonarlint").setup({
    --             server = {
    --                 cmd = {
    --                     sonar_language_server_path .. "/sonarlint-language-server.cmd",
    --                     "-stdio",
    --                     "-analyzers",
    --                     vim.fn.expand(analyzers_path .. "/sonarpython.jar"),
    --                     vim.fn.expand(analyzers_path .. "/sonarcfamily.jar"),
    --                     vim.fn.expand(analyzers_path .. "/sonarjava.jar"),
    --                     vim.fn.expand(analyzers_path .. "/sonargroovy.jar"),
    --                 },
    --             },
    --             filetypes = {
    --                 "python",
    --                 "cpp",
    --                 "java",
    --                 "groovy",
    --             },
    --         })
    --     end,
    -- },
    --
    -- {
    --     "mfussenegger/nvim-jdtls",
    --     -- dependencies = {
    --     --     "nvim-lua/lsp-status.nvim"
    --     -- },
    -- },
    --
    -- {
    --     "udalov/kotlin-vim",
    -- },
}
