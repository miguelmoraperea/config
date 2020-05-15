" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif


call plug#begin('~/.config/nvim/autoload/plugged')

Plug 'scrooloose/nerdtree'                          " File explorer
Plug 'vim-airline/vim-airline'                      " Status bar
Plug 'vim-airline/vim-airline-themes'               " Status bar
Plug 'mhinz/vim-startify'                           " Start screen
Plug 'neoclide/coc.nvim', {'branch': 'release'}     " Intellisense
Plug 'junegunn/rainbow_parentheses.vim'             " Rainbow parentheses
Plug 'morhetz/gruvbox'                              " Theme
Plug 'octol/vim-cpp-enhanced-highlight'             " C++ highlighter
Plug 'norcalli/nvim-colorizer.lua'
Plug 'Yggdroot/indentLine'
Plug 'preservim/nerdcommenter'
Plug 'majutsushi/tagbar'

" Fuzzy finder
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

" Git integration
"Plug 'mhinz/vim-signify'                            " Show modified lines on sidebar
Plug 'tpope/vim-fugitive'                           " Git integreation
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb'                            " Enables :Gbrowse to access Github URL's
Plug 'junegunn/gv.vim'                              " Git browser

" Testing
Plug 'vim-test/vim-test'                            " Run unit tests

" Python
Plug 'davidhalter/jedi-vim'
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}

" Jenkinsfile
Plug 'martinda/Jenkinsfile-vim-syntax'

" Nvim in browser
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

call plug#end()


" Automatically install missing plugins on startup
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
