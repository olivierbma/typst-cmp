if exists('g:loaded_typst_cmp') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
command! Whid lua require'typst-cmp'.typst-cmp()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_typst_cmp = 1
