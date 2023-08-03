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

function! fzfx#nvim#base_dir() abort
    return s:fzfx_base
endfunction
