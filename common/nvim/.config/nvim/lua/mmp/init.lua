require("mmp.packer")

vim.g.mapleader = " "
vim.opt.swapfile = false
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

vim.cmd(":highlight ExtraWhitespace guibg=#c94f6d")
vim.cmd([[:match ExtraWhitespace /\s\+$/]])

vim.cmd("colorscheme nightfox")
vim.cmd("highlight Comment cterm=italic gui=italic")

-- General remaps
vim.keymap.set("n", "<Leader>my", "<Cmd>so $MYVIMRC<CR>", { noremap = false })
vim.keymap.set("n", "<C-s>", "<Cmd>w<CR>", { noremap = false })
vim.keymap.set("n", "<C-h>", "<C-W><C-H>", { noremap = false })
vim.keymap.set("n", "<C-j>", "<C-W><C-J>", { noremap = false })
vim.keymap.set("n", "<C-k>", "<C-W><C-K>", { noremap = false })
vim.keymap.set("n", "<C-l>", "<C-W><C-L>", { noremap = false })
vim.keymap.set("n", "<Leader>c", "<Cmd>noh<CR>", { noremap = false })

-- NERDCommenter
vim.g.NERDSpaceDelims = 1
vim.g.NERDCompactSexyComs = 1
vim.g.NERDDefaultAlign = "left"
vim.cmd(" let g:NERDCustomDelimiters = { 'c': { 'left': '//' }, 'Jenkinsfile': { 'left': '//' } }")

-- NERDTree
vim.keymap.set("n", "<Leader>m", "<Cmd>NERDTreeToggle<CR>", { noremap = false })
vim.keymap.set("n", "<Leader>n", "<Cmd>NERDTreeFind<CR>", { noremap = false })
vim.g.NERDTreeQuitOnOpen = 1
vim.g.NERDTreeShowHidden = 1
vim.g.NERDTreeShowLineNumbers = 1
vim.g.NERDTreeWinSize = 60
vim.g.NERDTreeChDirMode = 2

-- Rainbow
vim.cmd("let g:rainbow#max_level = 16")
vim.cmd("let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]")
vim.cmd("autocmd FileType * RainbowParentheses")

-- Harpoon
require("mmp.harpoon")

-- Files
vim.api.nvim_set_keymap('n', '<Leader><Backspace>', '<Cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>',
    { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>mk', '<Cmd>lua require("harpoon.mark").add_file()<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>0', '<Cmd>lua require("harpoon.ui").nav_file(0)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>1', '<Cmd>lua require("harpoon.ui").nav_file(1)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>2', '<Cmd>lua require("harpoon.ui").nav_file(2)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>3', '<Cmd>lua require("harpoon.ui").nav_file(3)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>4', '<Cmd>lua require("harpoon.ui").nav_file(4)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>5', '<Cmd>lua require("harpoon.ui").nav_file(5)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>6', '<Cmd>lua require("harpoon.ui").nav_file(6)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>7', '<Cmd>lua require("harpoon.ui").nav_file(7)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>8', '<Cmd>lua require("harpoon.ui").nav_file(8)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>9', '<Cmd>lua require("harpoon.ui").nav_file(9)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>10', '<Cmd>lua require("harpoon.ui").nav_file(10)<CR>', { noremap = true })

-- Terminals
vim.api.nvim_set_keymap('n', '<Leader>t1', '<Cmd>lua require("harpoon.term").gotoTerminal(1)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>t2', '<Cmd>lua require("harpoon.term").gotoTerminal(2)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>t3', '<Cmd>lua require("harpoon.term").gotoTerminal(3)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>t4', '<Cmd>lua require("harpoon.term").gotoTerminal(4)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>t5', '<Cmd>lua require("harpoon.term").gotoTerminal(5)<CR>', { noremap = true })

-- Commands
vim.api.nvim_set_keymap('n', '<Leader><Backspace>c', '<Cmd>lua require("harpoon.cmd-ui").toggle_quick_menu()<CR>',
    { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>c1', '<Cmd>lua require("harpoon.term").sendCommand(1, 1)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>c2', '<Cmd>lua require("harpoon.term").sendCommand(2, 2)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>c3', '<Cmd>lua require("harpoon.term").sendCommand(3, 3)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>c4', '<Cmd>lua require("harpoon.term").sendCommand(4, 4)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>c5', '<Cmd>lua require("harpoon.term").sendCommand(5, 5)<CR>', { noremap = true })


-- LSP
require("mmp.lsp")
vim.lsp.set_log_level = "warn"
vim.g.lsp_log_verbose = 1

-- Telescope
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

-- nvim-cmp
require('mmp.nvim-cmp')

-- Colorizer
require 'colorizer'.setup()

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

-- null-ls
null_ls = require('null-ls')
null_ls.setup({
    sources = {
        null_ls.builtins.diagnostics.pylint,
        null_ls.builtins.diagnostics.flake8,
        null_ls.builtins.formatting.autopep8,
    },
})
