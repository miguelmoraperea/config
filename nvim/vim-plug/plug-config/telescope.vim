" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fd :lua R('mmp.telescope').find_files_under()<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb :lua R('mmp.telescope').buffers()<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>ft <cmd>Telescope git_files<cr>
nnoremap <leader>fr :lua R('mmp.telescope').search_dotfiles()<cr>
nnoremap <leader>fa :lua require'mmp.telescope'.git_branches()<cr>
nnoremap <leader>st :SpellCheck <bar> lua R('mmp.telescope').spellcheck()<cr>
nnoremap <leader>ma :lua R('mmp.telescope').mappings()<cr>
nnoremap <leader>ba :lua R('mmp.telescope').background_selector()<CR>
nnoremap <Leader>re :lua require'telescope.builtin'.lsp_references{}<cr>
nnoremap <Leader>di :lua require'telescope.builtin'.lsp_workspace_diagnostics{}<cr>
nnoremap <Leader>co :lua R('mmp.telescope').git_commits({})<cr>
nnoremap <Leader>gu :lua R('mmp.telescope').grep_word_under_cursor()<cr>

highlight TelescopeSelection      guifg=#D79921 gui=bold " selected item
highlight TelescopeSelectionCaret guifg=#CC241D " selection caret
highlight TelescopeMultiSelection guifg=#928374 " multisections
highlight TelescopeNormal         guibg=#00000  " floating windows created by telescope.

" Border highlight groups.
highlight TelescopeBorder         guifg=#98971a
highlight TelescopePromptBorder   guifg=#98971a
highlight TelescopeResultsBorder  guifg=#98971a
highlight TelescopePreviewBorder  guifg=#98971a

" Used for highlighting characters that you match.
highlight TelescopeMatching       guifg=#8ec07c

" Used for the prompt prefix
highlight TelescopePromptPrefix   guifg=red

lua require('mmp.telescope')
