local null_ls = require("null-ls")
null_ls.setup({
    sources = {
        -- null_ls.builtins.diagnostics.eslint,
        null_ls.builtins.completion.spell,
        null_ls.builtins.diagnostics.flake8,
        -- null_ls.builtins.diagnostics.pycodestyle,
        -- null_ls.builtins.diagnostics.vulture,
        -- null_ls.builtins.diagnostics.mypy,
        null_ls.builtins.formatting.blue,
        null_ls.builtins.formatting.jq,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.usort,
    },
})
