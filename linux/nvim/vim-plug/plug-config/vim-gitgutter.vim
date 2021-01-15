" Preview hunk
nmap gp <Plug>(GitGutterPreviewHunk)

" Navigate hunks
nmap [c <Plug>(GitGutterNextHunk)zz <Plug>(GitGutterPreviewHunk)
nmap ]c <Plug>(GitGutterPrevHunk)zz <Plug>(GitGutterPreviewHunk)

" Change base diff to origin/master
nmap gm :let g:gitgutter_diff_base = 'origin/master'<CR> :e <CR>

" Change base diff to origin/master
nmap gn :let g:gitgutter_diff_base = ''<CR> :e <CR>
"
" Change base diff to origin/master
nmap g, :let g:gitgutter_diff_relative_to = 'index'<CR> :e <CR>

" Toggle highlights
nmap gh :GitGutterLineHighlightsToggle<CR>

" Toggle fold
nmap gf :GitGutterFold<CR>

" Set icons
let g:gitgutter_sign_added = '✓'
let g:gitgutter_sign_modified = '⚠'
let g:gitgutter_sign_removed = '✖'

" Set colours
highlight GitGutterAdd    guifg=green ctermfg=2
highlight GitGutterChange guifg=yellow ctermfg=3
highlight GitGutterDelete guifg=red ctermfg=1
