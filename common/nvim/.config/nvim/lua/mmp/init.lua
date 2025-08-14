vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

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
vim.opt.foldopen = "all"
vim.opt.conceallevel = 3
vim.opt.termguicolors = true
vim.opt.colorcolumn = "100"
vim.opt.wrap = false

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
vim.keymap.set("n", "<C-z>", "<Cmd>cquit<CR>", { noremap = false })
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
vim.keymap.set("n", "<Leader>cf", "<Cmd>lua R('mmp.telescope').git_file_commits({})<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>gu", "<Cmd>lua R('mmp.telescope').grep_word_under_cursor()<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>te", "<Cmd>Telescope resume<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>tp", "<Cmd>lua R('mmp.telescope').team_pr_workflow()<cr>", { noremap = false })
vim.keymap.set("n", "<Leader>tu", "<Cmd>lua R('mmp.telescope').manual_user_pr_workflow()<cr>", { noremap = false })

-- DiffView shortcuts
vim.keymap.set("n", "<Leader>do", "<Cmd>DiffviewClose<cr>", { noremap = false })

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
        vim.opt.tabstop = 3
        vim.opt.shiftwidth = 3
    end,
})

-- Set autocmd to set textwidth to 99 for go files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "go" },
    callback = function()
        vim.opt.textwidth = 99
    end,
})

-- Create a new autocmd to run the current buffer file if is a python file
local run_python_file = function()
    -- Send to terminal 1 using harpoon
    vim.cmd("lua require('harpoon.tmux').sendCommand(1, 'i')")
    vim.cmd("lua require('harpoon.tmux').sendCommand(1, 'python3w " .. vim.fn.expand("%") .. "')")
    -- Go to terminal 1 using harpoon
    vim.cmd("lua require('harpoon.tmux').gotoTerminal(1)")
end

local init_python_project = function()
    local cwd = vim.fn.expand("%:p:h")
    vim.cmd("silent !init_python_project " .. cwd)
end

-- Python commands
vim.api.nvim_create_user_command("PythonRunFile", run_python_file, {})
vim.keymap.set("n", "<Leader>ru", ":PythonRunFile<CR>", { noremap = false })

-- Create a user command to run init_python_project and passing the cwd path
vim.api.nvim_create_user_command("PythonInitProject", init_python_project, {})

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

-- Remap Ctrl + l to Ctrl + ^
vim.keymap.set("n", "<C-g>", "<C-^>", { noremap = false })

-- Remove trailing spaces
--%s/\s\+$//e
vim.api.nvim_create_user_command("RemoveTrailingSpaces", [[%s/\s\+$//e]], {})
vim.api.nvim_create_user_command("RemoveTrailingSpacesConfirm", [[%s/\s\+$//gc]], {})

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

local yank_file_name = function()
    local path = vim.fn.expand("%:t")
    vim.fn.setreg("+", path)
    vim.cmd("echo 'Copied to clipboard: " .. path .. "'")
end
vim.api.nvim_create_user_command("YankFileName", yank_file_name, {})

local get_commit_under_cursor = function()
    return vim.fn.expand("<cword>")
end

-- Go to commit on github
local open_commit_under_cursor_in_github = function()
    local commit_hash = get_commit_under_cursor()
    local get_repo_url_cmd = "git config --get remote.origin.url | tr -d '\n'"
    -- Remove .git from the url
    get_repo_url_cmd = get_repo_url_cmd .. " | sed 's/\\.git$//'"
    local repo_url = vim.fn.system(get_repo_url_cmd)
    local url = repo_url .. "/commit/" .. commit_hash

    -- local cmd = "silent ! open -a Google\\ Chrome -n --args --new-window " .. url
    local cmd = "silent ! open -a 'Google Chrome' -n --args " .. url
    P(cmd)
    vim.cmd(cmd)
end
vim.api.nvim_create_user_command("GithubCommitOpen", open_commit_under_cursor_in_github, {})

-- https://github.com/search?q=org%3AShopify%20otel-collector.shopify-map-etl-stg.shopifysdp.com%3A8125&type=code
-- Search on Github
local search_on_github = function()
    -- Get the selected yanked text
    local raw_search_term = vim.fn.getreg('"')
    local raw_url = "https://github.com/search?q=org%3AShopify%20" .. raw_search_term .. "&type=code"
    local url = vim.fn.escape(raw_url, " \\/?=%")

    local cmd = "silent ! open -a 'Google Chrome' -n --args " .. url
    P(cmd)
    vim.cmd(cmd)
end
vim.api.nvim_create_user_command("GithubSearch", search_on_github, {})

local diffview_introduced_by_commit_under_cursor = function()
    local commit_hash = get_commit_under_cursor()
    local cmd = "DiffviewOpen " .. commit_hash .. "^!"
    vim.cmd(cmd)
end
vim.api.nvim_create_user_command(
    "DiffviewOpenIntroducedByCommitUnderCursor",
    diffview_introduced_by_commit_under_cursor,
    {}
)

local git_clean = function()
    local cmd = "git clean -fd"
    vim.fn.system(cmd)
end

local fetch_pr = function(pr_number)
    local cmd = "git fetch origin pull/" .. pr_number .. "/head:pr-" .. pr_number
    vim.fn.system(cmd)
    local cmd = "git checkout pr-" .. pr_number
    vim.fn.system(cmd)
end

local reset_pr = function(pr_number)
    local cmd = "git reset --soft $(git merge-base HEAD origin/main)"
    vim.fn.system(cmd)
end

local open_with_diffview = function()
    local cmd = "DiffviewOpen"
    vim.cmd(cmd)
end

-- Create a text input with nui.nvim
local get_pr_number = function()
    local Input = require("nui.input")
    local event = require("nui.utils.autocmd").event

    local input = Input({
        position = "50%",
        size = {
            width = 20,
        },
        border = {
            style = "single",
            text = {
                top = "PR Number",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
        },
    }, {
        prompt = "> ",
        default_value = "",
        on_close = function()
            print("Input Closed!")
        end,
        on_submit = function(value)
            print("Input Submitted: " .. value)
            git_clean()
            fetch_pr(value)
            reset_pr(value)
            open_with_diffview()
        end,
    })

    -- mount/open the component
    input:mount()

    -- unmount component when cursor leaves buffer
    input:on(event.BufLeave, function()
        input:unmount()
    end)
end
vim.api.nvim_create_user_command("PR", get_pr_number, {})

-- Team PR workflow command
vim.api.nvim_create_user_command("TeamPR", function()
    require('mmp.telescope').team_pr_workflow()
end, {})

-- Manual user PR workflow command
vim.api.nvim_create_user_command("UserPR", function()
    require('mmp.telescope').manual_user_pr_workflow()
end, {})

vim.api.nvim_create_user_command('DiffLatest', 'DiffviewOpen HEAD~1..HEAD', {})

vim.api.nvim_create_user_command('DiffPR', function(opts)
  local branch = opts.args ~= "" and opts.args or "HEAD"
  -- Get the last merge commit using git log
  local cmd = "git log --merges --format=%H " .. branch .. " | head -n 1"
  local last_merge = vim.fn.system(cmd):gsub("%s+$", "")
  vim.cmd("DiffviewOpen " .. last_merge .. "..." .. branch)
end, { nargs = '?' })

vim.api.nvim_create_user_command('DiffviewCloseKeepFile', function()
  local bufname = vim.fn.bufname('%')
  if bufname and bufname ~= '' then
    local clean_path = bufname:gsub("^diffview://", ""):gsub("%.git/%w+/", "")
    vim.cmd("DiffviewClose")
    vim.cmd("edit " .. clean_path)
    return
  end

  print("No valid entry found; closing Diffview without opening file.")
  vim.cmd("DiffviewClose")
end, {})

-- Remap jump to alternate file
vim.keymap.set("n", "<C-g>", "<C-6>", { noremap = false })

-- Remap { to }
vim.keymap.set("n", "{", "}", { noremap = false })

-- Remap } to (
vim.keymap.set("n", "(", "{", { noremap = false })

-- Set no wrap for .log files
vim.api.nvim_create_autocmd("BufRead", {
    pattern = { "*.log" },
    callback = function()
        vim.opt.wrap = false
    end,
})
