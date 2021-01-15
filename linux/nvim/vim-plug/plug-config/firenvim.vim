let g:fgs = {}
let g:fgs['alt'] = 'all'

let g:fls = {}
let g:fls['.*'] = {'cmdline': 'neovim', 'content': 'text', 'priority': 0, 'selector': 'textarea', 'takeover': 'always'}
let g:fls['github.com']  = { 'selector': 'textarea', 'priority': 1, 'filetype': 'markdown' }

let g:firenvim_config = { 'globalSettings': g:fgs, 'localSettings': g:fls }
