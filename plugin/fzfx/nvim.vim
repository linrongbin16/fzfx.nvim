if exists('g:loaded_fzfx')
    finish
endif
let g:loaded_fzfx=1

let s:is_win = has('win32') || has('win64')

function! fzfx#nvim#plugin_home()
    if s:is_win && &shellslash
        set noshellslash
        let base_dir = expand('<sfile>:p:h')
        set shellslash
        return base_dir
    else
        return expand('<sfile>:p:h')
    endif
endfunction
