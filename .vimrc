if $COLORTERM == 'gnome-terminal'
      set t_Co=256
endif

" Install vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vim-syntastic/syntastic'
Plug 'tpope/vim-fugitive'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'powerline/powerline', {'rtp': 'powerline/bindings/vim/'}
Plug 'zacanger/angr.vim'

call plug#end()

"NERDTree Settings
autocmd VimEnter * NERDTree
:let g:NERDTreeWinSize=50

" Set no wrap
set nowrap

" Turn ON syntax highlighting
syntax on

" Set tabs configuration
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Highlight matching search patterns
set hlsearch

" Include matching uppercase words with lowercase search term
set ignorecase

colorscheme angr

" Remap C-w
nnoremap <C-c> <C-w>

" Display line numbers on left margin
set number

" Setup powerline
set statusline=2

" Setup Exuberant Ctags
set tags=/home/miguel/Desktop/git/VesaGen2Development

" Setup ctlpvim

let g:ctrlp_map = '<c-p>' " Change the default mapping and the default command to invoke CtrlP.
let g:ctrlp_cmd = 'CtrlP' 
let g:ctrlp_working_path_mode = 'ra' " When invoked without an explicit starting directory.
let g:ctrlp_root_markers = ['pom.xml', '.p4ignore']
let g:ctrlp_switch_buffer = 'et'
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'             " If a file is already open, open it again in a new pane instead of switching to the existing pane
let g:ctrlp_user_command = 'find %s -type f'                                                " Use a custom file listing command

" Setup cscope

" Setup Syntastic
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" see :h syntastic-loclist-callback
"function! SyntasticCheckHook(errors)
"    if !empty(a:errors)
"        let g:syntastic_loc_list_height = min([len(a:errors), 10])
"    endif
"endfunction
