if exists('g:loaded_fzfx')
    finish
endif
let g:loaded_fzfx=1

let s:is_win = has('win32') || has('win64')

function! fzfx#nvim#plugin_home()
    echomsg "1"
    if s:is_win && &shellslash
        set noshellslash
        let base_dir = expand('<sfile>:p:h')
        set shellslash
        return base_dir
        echomsg "2"
    else
        echomsg "3"
        return expand('<sfile>:p:h')
    endif
endfunction
