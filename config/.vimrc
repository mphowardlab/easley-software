#!vim

:set ts=4
:set sw=4
:set expandtab

:set sts=4
:set backspace=indent,eol,start

:set ai

:set ruler
:syntax enable
:set nobackup

:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+$\|\t/
