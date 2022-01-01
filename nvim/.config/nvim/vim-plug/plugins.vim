
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

" Spelling
Plug 'inkarkat/vim-ingo-library'                    " Dependency for vim-spellcheck
Plug 'inkarkat/vim-spellcheck'

" Git integration
Plug 'tpope/vim-fugitive'                           " Git integration
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb'                            " Enables :Gbrowse to access Github URL's
Plug 'junegunn/gv.vim'                              " Git browser

" Testing
Plug 'vim-test/vim-test'                            " Run unit tests

" Python
" Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}

" Docker
Plug 'ekalinin/Dockerfile.vim'

" Lua
Plug 'euclidianAce/BetterLua.vim'
Plug 'nvim-lua/plenary.nvim'

" Try this Lua language server
" Plug 'summeko/lua-language-server'
" Plug 'tjdevries/nlua.vim'

" Jenkinsfile
Plug 'martinda/Jenkinsfile-vim-syntax'

" Nvim in browser
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" My plugins
Plug 'miguelmoraperea/vim-flex'
Plug 'miguelmoraperea/vim-jenkinsfile-validate'
Plug 'miguelmoraperea/vim-diffview'

" Learning Vim
Plug 'ThePrimeagen/vim-be-good'

" Try
Plug 'tjdevries/descriptive_maps.vim'
Plug 'kdheepak/lazygit.nvim'

" Bash
" Plug 'mads-hartmann/bash-language-server'

" LSP
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'

" Telescope
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug '/home/miguel/Desktop/git/telescope-file-browser.nvim'

" Python docstrings
Plug 'heavenshell/vim-pydocstring', { 'do': 'make install >> /tmp/pydocstring.log 2>&1', 'for': 'python' }

" Treesitter
Plug 'haorenW1025/completion-nvim'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'nvim-treesitter/playground'
Plug 'nvim-treesitter/completion-treesitter'

Plug 'lfv89/vim-interestingwords'

call plug#end()

" Automatically install missing plugins on startup
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
