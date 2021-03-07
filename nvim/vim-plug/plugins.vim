
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif


call plug#begin('~/.config/nvim/autoload/plugged')

Plug 'scrooloose/nerdtree'                          " File explorer
Plug 'vim-airline/vim-airline'                      " Status bar
Plug 'vim-airline/vim-airline-themes'               " Status bar
Plug 'mhinz/vim-startify'                           " Start screen
Plug 'junegunn/rainbow_parentheses.vim'             " Rainbow parentheses

Plug 'morhetz/gruvbox'                              " Theme

Plug 'octol/vim-cpp-enhanced-highlight'             " C++ highlighter
Plug 'norcalli/nvim-colorizer.lua'                  " Display colour codes with their actual colour in the background
Plug 'Yggdroot/indentLine'
Plug 'preservim/nerdcommenter'                      " Easy comments
Plug 'majutsushi/tagbar'                            " Show a tags bar with types and functions

" Git integration
Plug 'tpope/vim-fugitive'                           " Git integration
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb'                            " Enables :Gbrowse to access Github URL's
Plug 'junegunn/gv.vim'                              " Git browser

" Testing
Plug 'vim-test/vim-test'                            " Run unit tests

" Python
Plug 'davidhalter/jedi-vim'
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}

" C Language
Plug 'ericcurtin/CurtineIncSw.vim'

" Lua
Plug 'euclidianAce/BetterLua.vim'
Plug 'nvim-lua/plenary.nvim'

" Jenkinsfile
Plug 'martinda/Jenkinsfile-vim-syntax'

" Nvim in browser
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" My plugins
Plug 'miguelmoraperea/vim-flex'
Plug 'miguelmoraperea/vim-jenkinsfile-validate'

" Learning Vim
Plug 'ThePrimeagen/vim-be-good'

" Try
Plug 'tjdevries/descriptive_maps.vim'
Plug 'kdheepak/lazygit.nvim'

" LSP
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'

" Telescope
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

call plug#end()

" Automatically install missing plugins on startup
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
