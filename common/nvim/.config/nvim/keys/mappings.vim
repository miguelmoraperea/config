" Reload my VIMRC file
nnoremap <Leader>my :so $MYVIMRC<CR>

" Set nav for omnicomplete
inoremap <expr> <c-j> ("\<C-n>")
inoremap <expr> <c-k> ("\<C-p>")

" Use alt + hjkl to resize windows
nnoremap <M-j>    :resize -2<CR>
nnoremap <M-k>    :resize +2<CR>
nnoremap <M-h>    :vertical resize -2<CR>
nnoremap <M-l>    :vertical resize +2<CR>

" Easy CAPS
inoremap <c-u> <ESC>viwUi
nnoremap <c-u> viwU<Esc>

" Alternate way to save
nnoremap <C-s> :w<CR>

" Alternate way to quit
nnoremap <C-q> :q<CR>

" <TAB>: completion.
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

" Better tabbing
vnoremap < <gv
vnoremap > >gv

" Better window navigation
nnoremap <C-h> <C-W><C-H>
nnoremap <C-j> <C-W><C-J>
nnoremap <C-k> <C-W><C-K>
nnoremap <C-l> <C-W><C-L>

" Open window vertically
nnoremap <Leader>vw :vsplit <bar> enew<cr>

" Open window vertically
nnoremap <Leader>hw :split <bar> enew<cr>

" Close window
nnoremap <Leader>qw :close<CR>

" Clear highlighting
nnoremap <Leader>c :noh<cr>

" Close buffer
nnoremap <Leader>q :bd<cr>

" Tagbar
nmap <Leader>t :TagbarToggle<CR>

" Open buffers
nnoremap <Leader>b :Buffers<CR>

" Change workspace to current file
nnoremap <Leader>w :cd %:p:h<CR>

" Jump back to previous file
nnoremap <Leader>g <C-S-^><CR>

" Fold code
nnoremap <Leader>fo :foldopen<CR>
nnoremap <Leader>fc :foldclose<CR>

" Adding lines without entering insert mode
nnoremap <Leader>j o<ESC>
nnoremap <Leader>k O<ESC>

" Open a terminal at the side of the screen
nnoremap <Leader>te :vsplit<Bar>terminal<CR>

" Switch between source and header files
nnoremap <Leader>h :ClangdSwitchSourceHeader<CR>

" Trigger Vim-Flex
nnoremap <Leader>tf :call VimFlexTimeToFlex()<CR>

" Trigger Vim-Jenkinsfile-Validate
nmap <Leader>jv <Plug>VimJenkinsfileValidate<CR>

" Incremental window resize
nnoremap <silent> <Leader>+ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>

" Keep it centered
nnoremap n nzzzv
nnoremap N Nzzzv

" Diff from quickfix list
nnoremap <Leader>nd :call VimDiffNext()<CR>
nnoremap <Leader>pd :call VimDiffPrev()<CR>

" Diff on commit under the cursor
nnoremap <expr> <Leader>diff ':let g:gitgutter_diff_base = "'.expand('<cword>').'"<CR> <Bar> :Git difftool --name-only '.expand('<cword>').'<CR>'

" Git gutter navigate hunks
nnorema <Leader>nh :GitGutterNextHunk<cr>
nnorema <Leader>ph :GitGutterPrevHunk<cr>