vim.opt.swapfile = false
vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoread = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 10
vim.opt.timeoutlen = 500
vim.opt.updatetime = 100
vim.opt.signcolumn = "yes"
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.list = false
vim.opt.splitbelow = true
vim.opt.autoread = true
vim.opt.cmdheight = 1
vim.opt.wrapscan = false
vim.opt.fillchars = { diff = " " }
vim.opt.foldenable = false
vim.opt.conceallevel = 3
vim.opt.termguicolors = true

require("mmp.lazy")

vim.g.copilot_filetypes = { yaml = true, gradle = true, python = true }

if vim.fn.has("Linux") == 1 then
    if vim.fn.expand("$USER") == "mmora" then
        vim.g.python3_host_prog = "/home/mmora/Desktop/nvim_venv/bin/python"
    else
        vim.g.python3_host_prog = "/home/miguel/Desktop/nvim_venv/bin/python"
    end
else
    vim.g.python3_host_prog = "/Users/miguel/Desktop/nvim_venv/bin/python"
end

vim.api.nvim_set_hl(0, "@neorg.markup.italic.norg", { fg = "#7196d6", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { fg = "#c94f6d", undercurl = true })
vim.api.nvim_command("highlight link NvimTreeExecFile NvimTreeSpecialFile")

vim.cmd(":highlight ExtraWhitespace guibg=#c94f6d")
vim.cmd([[:match ExtraWhitespace /\s\+$/]])

vim.cmd("highlight Comment cterm=italic gui=italic")

vim.cmd(":highlight Normal guibg=none")
vim.cmd(":highlight NormalNC guibg=none")
vim.cmd(":highlight StatusLine guibg=none")
vim.cmd(":highlight NvimTreeNormal guibg=none")

-- -- General remaps
vim.keymap.set("n", "<Leader>my", "<Cmd>so $MYVIMRC<CR>", { noremap = false })
vim.keymap.set("n", "<C-s>", "<Cmd>w<CR>", { noremap = false })
vim.keymap.set("n", "<C-h>", "<C-W><C-H>", { noremap = false })
vim.keymap.set("n", "<C-j>", "<C-W><C-J>", { noremap = false })
vim.keymap.set("n", "<C-k>", "<C-W><C-K>", { noremap = false })
vim.keymap.set("n", "<C-l>", "<C-W><C-L>", { noremap = false })
vim.keymap.set("n", "<Leader>c", "<Cmd>noh<CR>", { noremap = false })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = false })

-- Indentation
vim.keymap.set("v", ">", ">gv", { noremap = false })
vim.keymap.set("v", "<", "<gv", { noremap = false })

-- -- LSP
require("mmp.lsp")
vim.lsp.set_log_level = "warn"
vim.g.lsp_log_verbose = 1

vim.keymap.set("n", "<leader>rn", "<Cmd>lua vim.lsp.buf.rename()", { noremap = false })

vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

-- -- Telescope
require("mmp.globals")
require("mmp.telescope")
vim.keymap.set("n", "<leader>ff", "<Cmd>Telescope find_files hidden=True<cr>", { noremap = false })
vim.keymap.set("n", "<leader>fd", "<Cmd>lua R('mmp.telescope').find_files_under<CR>", { noremap = false })
vim.keymap.set("n", "<leader>fg", "<Cmd>Telescope live_grep<cr>", { noremap = false })
vim.keymap.set("n", "<leader>fb", "<Cmd>lua R('mmp.telescope').buffers()<cr>", { noremap = false })
vim.keymap.set("n", "<leader>fh", "<Cmd>Telescope help_tags<cr>", { noremap = false })
vim.keymap.set("n", "<leader>ft", "<Cmd>Telescope git_files<cr>", { noremap = false })
vim.keymap.set("n", "<leader>fr", "<Cmd>lua R('mmp.telescope').search_dotfiles()<cr>", { noremap = false })
vim.keymap.set("n", "<leader>fa", "<Cmd>lua require'mmp.telescope'.git_branches()<cr>", { noremap = false })
vim.keymap.set("n", "<leader>st", "<Cmd>SpellCheck <bar> lua R('mmp.telescope').spellcheck()<cr>", { noremap = false })
vim.keymap.set("n", "<leader>ma", "<Cmd>lua R('mmp.telescope').mappings()<cr>", { noremap = false })
vim.keymap.set("n", "<leader>bo", "<Cmd>lua R('mmp.telescope').background_selector()<CR>", { noremap = false })
vim.keymap.set("n", "<Leader>re", "<Cmd>lua require'telescope.builtin'.lsp_references{}<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>di", "<Cmd>lua require'telescope.builtin'.diagnostics{}<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>co", "<Cmd>lua R('mmp.telescope').git_commits({})<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>gu", "<Cmd>lua R('mmp.telescope').grep_word_under_cursor()<cr>", { noremap = false })

vim.keymap.set("n", "<Leader>fp", ":lua require('telescope').extensions.project.project()<CR>", { noremap = false })

-- Precise Trim Whitespaces
vim.cmd([[
function! PreciseTrimWhiteSpace()
  " We need to save the view because the substitute command might
  " or might not move the cursor, depending on whether it finds
  " any whitespace.
  let saved_view = winsaveview()

  " Remove white space. Ignore "not found" errors. Don't change jumplist.
  if &modifiable
    keepjumps '[,']s/\s\+$//e

    " Move cursor back if necessary.
    call winrestview(saved_view)
  endif
endfunction
]])

vim.cmd([[
augroup PreciseTrimWhiteSpace
  autocmd!
  autocmd InsertLeave * call PreciseTrimWhiteSpace()
augroup end
]])

-- Highlight on yank
vim.cmd([[
augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=100 }
augroup END
]])

-- Set autocmd to set textwidth to 120 for neorg files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "norg" },
    callback = function()
        vim.opt.textwidth = 120
    end,
})

-- Create a new autocmd to run the current buffer file if is a python file
local run_python_file = function()
    -- Send to terminal 1 using harpoon
    vim.cmd("lua require('harpoon.tmux').sendCommand(1, 'i')")
    vim.cmd("lua require('harpoon.tmux').sendCommand(1, 'python3 " .. vim.fn.expand("%") .. "')")
    -- Go to terminal 1 using harpoon
    vim.cmd("lua require('harpoon.tmux').gotoTerminal(1)")
end

-- Create a user command to run run_python_file
vim.api.nvim_create_user_command("RunPythonFile", run_python_file, {})
vim.keymap.set("n", "<Leader>ru", ":RunPythonFile<CR>", { noremap = false })

-- Set syntax for thrift files
vim.cmd([[
au BufRead,BufNewFile *.thrift set filetype=thrift
au! Syntax thrift source ~/.vim/thrift.vim
]])

-- Set syntax for build files
vim.cmd([[
au BufRead,BufNewFile *.build set filetype=xml
]])

-- Keymay for switching between source and header files
vim.keymap.set("n", "go", ":ClangdSwitchSourceHeader<CR>", { noremap = false })

-- Remove trailing spaces
--%s/\s\+$//e
vim.api.nvim_create_user_command("RemoveTrailingSpaces", [[%s/\s\+$//e]], {})
vim.api.nvim_create_user_command("RemoveTrailingSpacesConfirm", [[%s/\s\+$//gc]], {})

-- Autocmd to remove trailing empty lines at the end of the file
-- vim.api.nvim_create_autocmd("BufWritePre", {
--     pattern = { "*" },
--     callback = function()
--         vim.cmd([[%s#\($\n\s*\)\+\%$##]])
--     end,
-- })

-- Get file path
local yank_file_path_full = function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.cmd("echo 'Copied to clipboard: " .. path .. "'")
end
vim.api.nvim_create_user_command("YankFilePathFull", yank_file_path_full, {})

local yank_file_path_relative = function()
    local path = vim.fn.expand("%")
    vim.fn.setreg("+", path)
    vim.cmd("echo 'Copied to clipboard: " .. path .. "'")
end
vim.api.nvim_create_user_command("YankFilePathRelative", yank_file_path_relative, {})

-- jdtls_lsp
-- vim.cmd([[
-- augroup jdtls_lsp
--     autocmd!
--     autocmd FileType java lua require('mmp.jdtls_setup').setup()
-- augroup end
-- ]])

-- -- Create an autocmd to run when the user saves a file
-- vim.api.nvim_create_autocmd("BufWritePre", {
--     pattern = { "*" },
--     callback = function()
--         if vim.bo.readonly then
--             vim.schedule(function()
--                 print("This is a read only file")
--             end)
--
--             -- Open file for add in perforce
--             vim.cmd("silent !p4 edit " .. vim.fn.expand("%"))
--         end
--     end,
-- })

-- -- Rainbow
-- vim.cmd("let g:rainbow#max_level = 16")
-- vim.cmd("let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]")
-- vim.cmd("autocmd FileType * RainbowParentheses")

-- -- Symbols outline
-- require("symbols-outline").setup({ show_relative_numbers = true, width=40, keymaps = { close = { nil } } })
-- vim.keymap.set("n", "<Leader>t", ":SymbolsOutline<CR>", { noremap = false })

-- -- Test
-- vim.keymap.set("n", "<Leader>tf", ":TestFile<CR>", { noremap = false })
-- vim.keymap.set("n", "<Leader>tn", ":TestNearest<CR>", { noremap = false })
-- vim.keymap.set("n", "<Leader>tl", ":TestLast<CR>", { noremap = false })

-- -- Debugger
-- require('dap')
-- require("dapui").setup()
-- require('dap-python').setup('/home/miguel/Desktop/nvim_venv/bin/python')
-- require('dap-python').test_runner = 'unittest'

-- vim.keymap.set("n", "<Leader>db", ":lua require('dap').toggle_breakpoint()<CR>", { noremap = false })
-- vim.keymap.set("n", "<Leader>dc", ":lua require('dap').continue()<CR>", { noremap = false })
-- vim.keymap.set("n", "<Leader>do", ":lua require('dap').step_over()<CR>", { noremap = false })
-- vim.keymap.set("n", "<Leader>de", ":lua require('dap').step_into()<CR>", { noremap = false })

-- vim.keymap.set("n", "<leader>dfu", ":lua require('dap-python').test_method()<CR>", { noremap = false })
-- vim.keymap.set("n", "<leader>dca", ":lua require('dap-python').test_class()<CR>", { noremap = false })
-- vim.keymap.set("n", "<leader>dse", ":lua require('dap-python').debug_selection()<CR>", { noremap = false })

-- vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg='#993939', bg='#31353f' })
-- vim.api.nvim_set_hl(0, 'DapLogPoint', { fg='#61afef', bg='#31353f' })
-- vim.api.nvim_set_hl(0, 'DapStopped', { fg='#98c379', bg='#31353f' })

-- vim.fn.sign_define('DapBreakpoint', { text='', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })
-- vim.fn.sign_define('DapBreakpointCondition', { text='ﳁ', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })
-- vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl= 'DapBreakpoint' })
-- vim.fn.sign_define('DapLogPoint', { text='', texthl='DapLogPoint', linehl='DapLogPoint', numhl= 'DapLogPoint' })
-- vim.fn.sign_define('DapStopped', { text='', texthl='DapStopped', linehl='DapStopped', numhl= 'DapStopped' })

-- vim.keymap.set("n", "<Leader>dd", ":lua require('dapui').toggle()<CR>", { noremap = false })
