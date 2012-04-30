""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Dmenu assisted awesomeness for Vim
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	File finder, with fuzz.
" Last Change:	2012-04-30
" License:	Vim License (see :help license)
" Location:	plugin/u-dmen.vim
" Website:	https://github.com/dahu/u-dmen
"
" See u-dmen.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help u-dmen
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:udmen_version = '0.1'

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development
"if exists("g:loaded_u-dmen")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_u-dmen = 1

" Options: {{{1
if !exists('g:somevar')
  let g:somevar = 0
endif

" UniqMap Library {{{1
" Original Code by Houl
" Refactored by Barry Arthur, 20 Apr 2012

" UniqMapFirst({list}, {map-expr})
"
" Remove duplicates from {list}, after applying {map-expr} (see :h map()).
" The instance with the lowest index is kept.
"
function! UniqMapFirst(list, mapexpr) "{{{
  let mlist = map(copy(a:list), a:mapexpr)
  let idx = len(a:list) - 1
  while idx >= 1
    if index(mlist, mlist[idx]) < idx
      call remove(a:list, idx)
    endif
    let idx -= 1
  endwhile
  return a:list
endfunction "}}}

" UniqMapLast({list}, {map-expr})
"
" Remove duplicates from {list}, after applying {map-expr} (see :h map()).
" The instance with the highest index is kept.
"
function! UniqMapLast(list, mapexpr) "{{{
  return reverse(UniqMapFirst(reverse(a:list), a:mapexpr))
endfunction "}}}

" UniqMap({list}, {map-expr}[, {keep-last}])
"
" Remove duplicates from {list}, after applying {map-expr} (see :h map()).
" The instance with the lowest index is kept, unless {keep-last} is non-zero.
"
function! UniqMap(list, mapexpr, ...) "{{{
  if a:0 >= 1 && a:1
    return UniqMapLast(a:list, a:mapexpr)
  else
    return UniqMapFirst(a:list, a:mapexpr)
  endif
endfunction "}}}
"}}}1

" Private Functions: {{{1

function s:UDmenDmenu(...)
  return "dmenu -l 25 -p 'F:' -i"
endfunction

function! s:UDmenFind()
  let dmenu_cmd = s:UDmenDmenu()
  let pathlist = split(&path, '\\\@<!,')
  let buffer_path = ''
  let current_path = ''
  if index(pathlist, '.') != -1
    let buffer_path = fnamemodify(expand('%'), ":p:h")
  endif
  if index(pathlist, '') != -1
    let current_path = getcwd()
  endif
  let find_paths = filter(pathlist, 'v:val != "."')
  call add(find_paths, buffer_path)
  call add(find_paths, current_path)
  let find_paths = filter(find_paths, 'v:val != ""')
  let find_paths = UniqMap(find_paths, 'v:val')
  let path = system("find " . join(find_paths, " ") . " -name '.git' -prune -o -print | sort | " . dmenu_cmd)
  if path != ""
    exe "e " . path
  endif
endfunction

function! s:UDmenCD()
  let dmenu_cmd = s:UDmenDmenu()
  let path = system(dmenu_cmd . " < ~/.vim/dirs")
  if path != ""
    exe "cd " . path
    pwd
  endif
endfunction

" Public Interface: {{{1

" Maps: {{{1
nnoremap <Plug>u-dmen_find :call <SID>UDmenFind()<CR>
nnoremap <Plug>u-dmen_cd   :call <SID>UDmenCD()<CR>

if !hasmapto('<Plug>u-dmen_find')
  nmap <silent> <leader>e <Plug>u-dmen_find
endif

if !hasmapto('<Plug>u-dmen_cd')
  nmap <silent> <leader>cd <Plug>u-dmen_cd
endif

" Commands: {{{1
"command! -nargs=0 -bar MyCommand1 call <SID>MyScriptLocalFunction()
"command! -nargs=0 -bar MyCommand2 call MyPublicFunction()

" Autocommands {{{1
"augroup UDmen
  "au!
  "au BufRead * call <SID>UDmenCollectDirectory()
"augroup END

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:

