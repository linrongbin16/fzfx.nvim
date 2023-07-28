if exists('g:loaded_fzfx')
    finish
endif
let g:loaded_fzfx=1

let s:is_win = has('win32') || has('win64')

if s:is_win && &shellslash
    set noshellslash
    let s:base_dir = expand('<sfile>:p:h:h')
    set shellslash
else
    let s:base_dir = expand('<sfile>:p:h:h')
endif

if s:is_win
    let s:bin_dir = s:base_dir.'\bin\'
else
    let s:bin_dir = s:base_dir.'/bin/'
endif

let $_FZFX_BASE_DIR=s:base_dir
let $_FZFX_BIN_DIR=s:bin_dir
