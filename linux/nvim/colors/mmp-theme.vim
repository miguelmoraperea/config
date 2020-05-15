" Show syntax highlighting groups for word under cursor
nmap <C-S-O> :call <SID>SynStack()<CR>
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc


colorscheme default


"set background=dark

" Gutter
:highlight SignColumn guibg=none

"highlight Normal guibg=#080808
highlight Normal guibg=#1c1c1c
highlight cCommentL guifg=#808080
highlight Cursorline guibg=#585858
highlight Visual  guifg=#000000 guibg=#FFFFFF gui=none
highlight LineNr   guifg=#87af00 guibg=none gui=none

" Spaces and Tabs
highlight Whitespace guifg=#444444 guibg=none gui=none
match Whitespace /\s/
match Whitespace /\t/

" Pop-up menu colors
highlight Pmenu guibg=#000000 guifg=#ffffff gui=none
highlight PmenuSel guibg=#ffffff guifg=#000000

" C Language
highlight cType guifg=#ff00ff
highlight cBoolean guifg=#d78700
highlight cConstant guifg=#ff5fff


" Python
highlight pythonFunction guifg=#ff00ff guibg=none gui=none
highlight pythonString guifg=#00af00 guibg=none gui=none
highlight link pythonTripleQuotes pythonString

" Highlight self
syn keyword pythonSelf self
highlight def link pythonSelf Special

" highlight pythonAttribute guifg=#00ffff guibg=none gui=none
