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

" Private Functions: {{{1

" Remove duplicates from a list
function! s:Uniq(list) "{{{1
  let mlist = copy(a:list)
  let idx = len(a:list) - 1
  while idx >= 1
    if index(mlist, mlist[idx]) < idx
      call remove(a:list, idx)
    endif
    let idx -= 1
  endwhile
  return a:list
endfunction "}}}

function! s:UDmenDmenu(prompt)
  return "dmenu -l 25 -i -p '" . a:prompt . ":'"
endfunction

function! s:UDmenFindInPath(path, dmenu_cmd)
  let pathlist = split(a:path, '\\\@<!,')
  let buffer_path = ''
  let current_path = ''
  if index(pathlist, '.') != -1
    let buffer_path = fnamemodify(expand('%'), ":p:h")
  endif
  if index(pathlist, '') != -1
    let current_path = getcwd()
  endif
  " construct find_paths with absolute paths, removing blanks and duplicates
  let find_paths = filter(pathlist, 'v:val != "."')
  call add(find_paths, buffer_path)
  call add(find_paths, current_path)
  let find_paths = s:Uniq(filter(find_paths, 'v:val != ""'))
  " call dmenu with uniqed find list of all paths, ignoring git files
  " TODO: This should allow for user-specifiable ignores and a broader default
  return system("find " . join(find_paths, " ") . " -name '.git' -prune -o -print | sort -u | " . a:dmenu_cmd)
endfunction

function! s:UDmenFind()
  let dmenu_cmd = s:UDmenDmenu('Find')
  let file = s:UDmenFindInPath(&path, dmenu_cmd)
  if file != ""
    exe "e " . file
  endif
endfunction

" TODO: Add lcd option
" " change local cd
" " TODO: remap this
" nnoremap <leader>lcd  :lcd %:h<cr>:pwd<cr>
function! s:UDmenCD()
  let dmenu_cmd = s:UDmenDmenu('CD')
  let path = system(dmenu_cmd . " < ~/.vim/dirs")
  if path != ""
    exe "cd " . path
    pwd
  endif
endfunction

function! s:UDmenGrep(default, ...)
  let prompt = "grep"
  if a:0
    let prompt = a:1
  endif
  let pattern = input(prompt . ':', a:default)
  "TODO: This is a security risk - should escape pattern
  let old_search = @/
  let matches = join(vimple#redir('g/' . pattern . '/p'), "\n")
  let @/ = old_search
  let dmenu_cmd = s:UDmenDmenu(prompt)
  let match = system("echo " . shellescape(matches) . " |" . dmenu_cmd)
  if len(match) > 0
    exe split(match)[0]
  endif
endfunction

function! s:UDmenTOC()
  "TODO: the default should be filetype based
  let default = '^\s*function'
  let entry = s:UDmenGrep(default, 'TOC')
  if entry != ''
    exe split(entry, " ")[0]
  endif
endfunction

function! s:UDmenStoreDirectory()
  let dirs = readfile(expand("$HOME/.vim/dirs"))
  call add(dirs, fnamemodify(expand('%'), ":p:h"))
  call writefile(s:Uniq(sort(dirs)), expand("$HOME/.vim/dirs"))
endfunction

" Public Interface: {{{1

" Maps: {{{1
nnoremap <Plug>u-dmen_find :call <SID>UDmenFind()<CR>
nnoremap <Plug>u-dmen_cd   :call <SID>UDmenCD()<CR>
nnoremap <Plug>u-dmen_toc  :call <SID>UDmenTOC()<CR>
nnoremap <Plug>u-dmen_grep :call <SID>UDmenGrep('')<CR>

if !hasmapto('<Plug>u-dmen_find')
  nmap <silent> <leader>ge <Plug>u-dmen_find
endif

if !hasmapto('<Plug>u-dmen_cd')
  nmap <silent> <leader>gc <Plug>u-dmen_cd
endif

if !hasmapto('<Plug>u-dmen_toc')
  nmap <silent> <leader>gt <Plug>u-dmen_toc
endif

if !hasmapto('<Plug>u-dmen_grep')
  nmap <silent> <leader>gg <Plug>u-dmen_grep
endif

" Autocommands {{{1
augroup UDmen
  au!
  au BufRead * call <SID>UDmenStoreDirectory()
augroup END

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:
