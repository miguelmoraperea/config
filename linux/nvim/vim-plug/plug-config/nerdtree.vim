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

" Sync open file with NERDTree
" Check if NERDTree is open or active
function! IsNERDTreeOpen()
  return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction

" Call NERDTreeFind iff NERDTree is active, current window contains a modifiable
" file, and we're not in vimdiff
function! SyncTree()
  if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
    wincmd p
  endif
endfunction

" Highlight currently open buffer in NERDTree
autocmd BufEnter * call SyncTree()
