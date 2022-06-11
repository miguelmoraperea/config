nnoremap <Leader>m :NERDTreeToggle<Enter>       " Toggle
nnoremap <Leader>n :NERDTreeFind<Enter>         " Find opened buffer

let NERDTreeQuitOnOpen = 1
let NERDTreeMapOpenInTab='<c-t>'

" Enable line numbers
let NERDTreeShowLineNumbers=1

" Window size
let NERDTreeWinSize = 60

" Make sure relative line numbers are used
autocmd FileType nerdtree setlocal relativenumber

let g:NERDTreeChDirMode = 2
