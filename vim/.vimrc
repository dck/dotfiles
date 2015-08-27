set nocompatible

filetype off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

" Set filetype stuff to on
filetype on
filetype plugin on
filetype indent on

scriptencoding utf-8
set encoding=utf-8

set tabstop=4
set shiftwidth=4
set smarttab
set et
set autoindent
set cindent
set backspace=indent,eol,start

set wrap

set showmode
set hlsearch
set ignorecase
set showmatch
set incsearch

set laststatus=2
set lz

" Appearance
syntax on
colorscheme  Tomorrow-Night
set nocursorline
set nocursorcolumn
set number
set background=dark

set listchars=tab:>-,trail:⋅,nbsp:⋅
set list

" Custom
if v:version >= 703
    "undo settings
    set undodir=~/.vim/undofiles
    set undofile

    set colorcolumn=81 "mark the ideal max text width
        let s:color_column_old = 0
endif

autocmd Filetype gitcommit setlocal textwidth=72 colorcolumn=50,72

" Plugins
let g:NERDTreeWinSize = 25
map <F2> :NERDTreeToggle<CR>

let g:indentLine_char = '│'
