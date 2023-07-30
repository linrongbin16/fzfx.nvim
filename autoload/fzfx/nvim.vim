if exists('g:loaded_fzfx')
    finish
endif
let g:loaded_fzfx=1

let s:is_win = has('win32') || has('win64')

if s:is_win && &shellslash
    set noshellslash
    let s:fzfx_base = expand('<sfile>:p:h:h:h')
    set shellslash
else
    let s:fzfx_base = expand('<sfile>:p:h:h:h')
endif

if s:is_win
    let s:fzfx_bin = s:fzfx_base.'\bin\'
else
    let s:fzfx_bin = s:fzfx_base.'/bin/'
endif

function! fzfx#nvim#plugin_home() abort
    return s:fzfx_base
endfunction

function! fzfx#nvim#plugin_bin() abort
    return s:fzfx_bin
endfunction
