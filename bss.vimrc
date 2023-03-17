" BashShellSetup : VIM Setup
" File: BashShellSetup/bss.vimrc
" Author: Amit Roy amitrupu@gmail.com
" Date: 28-Jan-2021

" To use it, copy it to
"     for Unix and OS/2:  ~/.vimrc
"  for MS-DOS and Win32:  $VIM\_vimrc

" general setup
set nocompatible 
set nobackup

set bs=2

" edit setup
set noautoindent
set smartindent
set smarttab
set tabstop=4       " tab width is 4 spaces
set shiftwidth=4    " indent with 4 spaces

" search setup
set showmode
set showmatch
set hlsearch
set shiftwidth=4
set ruler
"set number

" syntax setup
" color torte
" color delek
syntax enable
" highlight Cursor ctermfg=Yellow

"keymap --- F1-9 key mapping ---
"keymap F1 : help on current key mapping
nmap <F1> :!sed -n 's/"\s*keymap\s*\(.*\)/\1/p' ~/.vimrc <CR>
"keymap F2 : save file
map <F2> :w <CR>
"keymap F3 : reload file
map <F3> :e! <CR>
"keymap F4 : toggle line number display
map <F4> :set invnumber <CR>
"keymap F5 : replace tabs with spaces
map <silent> <F5> :set expandtab <CR>
    \ :retab <CR>
    \ :set noexpandtab <CR>
"keymap F6 : toggle syntax highlighting
map <silent> <F6> : if exists("g:syntax_on") <BAR>              
    \     syntax off <BAR>                             
    \ else <BAR>                                     
    \     syntax enable <BAR>                                  
    \ endif <CR>
"keymap F7 : toggle indenting for paste
set pastetoggle=<F7>
"keymap F8 : -- unused --
"keymap F9 : toggle light & dark theme
map <silent> <F9> : if &bg=="dark" <BAR>              
    \     set bg=light <BAR>                             
    \ else <BAR>                                     
    \     set bg=dark <BAR>                                  
    \ endif <CR>

" mouse mapping
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" read my vimrc
:let $uservimrc = "~/.vimrc." . $USER
:if filereadable(expand($uservimrc))
:	source $uservimrc
:endif
