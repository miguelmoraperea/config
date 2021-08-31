" Set leader key
let g:mapleader = "\<Space>"

syntax enable                           " Enables syntax highlighting
set hidden                              " Required to keep multiple buffers open with unsaved changes
set nowrap                              " Display long lines as just one line
set encoding=utf-8                      " The encoding displayed
set pumheight=10                        " Makes popup menu smaller
set fileencoding=utf-8                  " The encoding written to file
set ruler                               " Show the cursor position all the time
set cmdheight=2                         " More space for displaying messages
set iskeyword+=-                        " Treat dash separated words as a word text object"
set mouse=a                             " Enable your mouse
set splitbelow                          " Horizontal splits will automatically be below
set splitright                          " Vertical splits will automatically be to the right
set t_Co=256                            " Support 256 colors
set conceallevel=0                      " So that I can see `` in markdown files
set tabstop=4                           " Insert 4 spaces for a tab
set shiftwidth=4                        " Change the number of space characters inserted for indentation
set smarttab                            " Makes tabbing smarter will realize you have 2 vs 4
set expandtab                           " Converts tabs to spaces
set smartindent                         " Makes indenting smart
set autoindent                          " Good auto indent
set laststatus=0                        " Always display the status line
set number                              " Line numbers
set cursorline                          " Enable highlighting of the current line
set background=dark                     " tell vim what the background color looks like
set showtabline=2                       " Always show tabs
set noshowmode                          " We don't need to see things like -- INSERT -- anymore
set nobackup                            " This is recommended by coc
set nowritebackup                       " This is recommended by coc
set updatetime=300                      " Faster completion
set timeoutlen=500                      " By default timeoutlen is 1000 ms
set formatoptions-=cro                  " Stop newline continuation of comments
set clipboard=unnamedplus               " Copy paste between vim and everything else
set colorcolumn=80,100
set noswapfile                          " Swap files are used on multi-user system to prevent multiple instances of vim to edit the same file. I don't need this, so disable it
set autoread                            " When a file has changed on disk, just load it. Don't ask
set ignorecase                          " Case insensitive search
set smartcase                           " If there are uppercase letters, become case-sensitive
set gdefault                            " Use the `g` flag by default
set diffopt+=vertical
set diffopt+=filler,context:15
set scrolloff=10
set nowrapscan                          " Do not wrap searches to the beginning of the file
set spell
set spelllang=en_us

" Relative number bar
:set number relativenumber

:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END

au! BufWritePost $MYVIMRC source %      " auto source when writing to init.vm alternatively you can run :source $MYVIMRC

" You can't stop me
cmap w!! w !sudo tee %

set background=dark
let g:gruvbox_colors = { 'bright_red': ['#ffff00', 0] }
colorscheme gruvbox

" Enable true color
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" Remove background colour
highlight Normal guibg=none

let g:airline_theme='base16'

" Set current directory as workspace
" autocmd BufEnter * lcd %:p:h

" Show Tabs
set list
set listchars+=tab:>-

let g:virtualenv_directory = $PWD

" Define python-neovim packages, specially needed when working with virtual environments
if len(glob('/usr/lib/python2*/dist-packages/neovim/__init__.py', 1))
let g:python_host_prog="/usr/bin/python2"
endif
if len(glob('/usr/lib/python3*/dist-packages/neovim/__init__.py', 1))
let g:python3_host_prog="/usr/bin/python3"
endif

" File Types
au BufRead,BufNewFile *.kl1 set filetype=c
au BufRead,BufNewFile *.inc set filetype=c
au BufRead,BufNewFile *.html set shiftwidth=2 softtabstop=2 tabstop=2 expandtab
au BufRead,BufNewFile README set syntax=rst
au BufRead,BufNewFile *.md setlocal syntax=markdown colorcolumn=100 textwidth=99 wrap linebreak
autocmd FileType rst setlocal syntax=rst shiftwidth=3 softtabstop=3 tabstop=3 expandtab colorcolumn=100 textwidth=99

" Disable quote concealing in JSON files
autocmd Filetype json
  \ let g:indentLine_setConceal = 0 |
  \ let g:vim_json_syntax_conceal = 0

" Print the highlight groups associated with the word under the cursor
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Display comments in italics
highlight Comment cterm=italic gui=italic

let g:coc_global_extensions=[
    \'coc-spell-checker',
    \'coc-yaml',
    \'coc-python',
    \'coc-sh',
    \'coc-json',
    \'coc-docker',
    \'coc-html',
\]

" Define auto-complete options
set completeopt=menuone,noinsert,noselect
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

" Define LSP servers
lua require'lspconfig'.tsserver.setup{ on_attach=require'completion'.on_attach }
lua require'lspconfig'.clangd.setup{}
lua require'lspconfig'.bashls.setup{}
lua require'lspconfig'.dockerls.setup{}

" Python
lua require'lspconfig'.pylsp.setup{}
lua require'lspconfig'.pylsp.setup{on_attach=require'completion'.on_attach}

" Ignore CamelCase words when spell checking
fun! IgnoreCamelCaseSpell()
  syn match CamelCase /\<[A-Z][a-z]\+[A-Z].\{-}\>/ contains=@NoSpell transparent
  syn cluster Spell add=CamelCase
endfun

autocmd BufRead,BufNewFile * :call IgnoreCamelCaseSpell()

lua require('mmp.globals')
" lua require('mmp.indent-blankline')
