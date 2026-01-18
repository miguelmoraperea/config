local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        -- Only enable stylua for Lua formatting
        null_ls.builtins.formatting.stylua,
        -- All other sources disabled to prevent conflicts
        -- Python formatting/linting handled by ruff_lsp
        -- Python type checking handled by Pyright
    },
    debug = false,
    diagnostics_format = "[#{c}] #{m} (#{s})",
})
