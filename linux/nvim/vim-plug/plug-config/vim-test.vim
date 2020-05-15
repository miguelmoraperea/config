nmap <leader>nn :TestNearest<CR>
nmap <leader>nn :TestNearest<CR>

nmap <leader>tf :TestFile<CR>
nmap <leader>ft :TestFile<CR>

nmap <leader>ts :TestSuite<CR>
nmap <leader>st :TestSuite<CR>

nmap <leader>tl :TestLast<CR>
nmap <leader>lt :TestLast<CR>

nmap <leader>tv :TestVisit<CR>
nmap <leader>vt :TestVisit<CR>


function! CoverageNearest()
    TestNearest
    sleep 500m
    execute '!rm -rf htmlcov'
    execute '!coverage html'
    execute '!firefox htmlcov/index.html'
endfunction
nmap <leader>tn :call CoverageNearest()<CR>
nmap <leader>nt :call CoverageNearest()<CR>
