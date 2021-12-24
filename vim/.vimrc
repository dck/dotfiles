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

set updatetime=500
set tabstop=4
set shiftwidth=4

" set clipboard=unnamed
set smarttab
set et
set autoindent
set cindent
set backspace=indent,eol,start

set wrap

set showmode
set incsearch
set hlsearch
set ignorecase
set smartcase
set showmatch

set laststatus=2
set lz

" Appearance
syntax on
colorscheme gruvbox
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
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1

let g:indentLine_char = '│'

augroup myfiletypes
    autocmd!
    autocmd FileType ruby,eruby,yaml,markdown set ai sw=2 sts=2 et
augroup END

set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,vendor/gems/*

" Keys
let mapleader = ","

map <F2> :NERDTreeToggle<CR>

nnoremap <Leader>s :w<CR>
nnoremap <Leader>e :bnext<CR>
nnoremap <Leader>w :bprev<CR>
nnoremap <Leader>q :bdelete<CR>
nnoremap <Leader>n :NERDTreeToggle<CR>

nmap <leader>1 <Plug>BufTabLine.Go(1)
nmap <leader>2 <Plug>BufTabLine.Go(2)
nmap <leader>3 <Plug>BufTabLine.Go(3)
nmap <leader>4 <Plug>BufTabLine.Go(4)
nmap <leader>5 <Plug>BufTabLine.Go(5)
nmap <leader>6 <Plug>BufTabLine.Go(6)
nmap <leader>7 <Plug>BufTabLine.Go(7)
nmap <leader>8 <Plug>BufTabLine.Go(8)
nmap <leader>9 <Plug>BufTabLine.Go(9)
nmap <leader>0 <Plug>BufTabLine.Go(10)

nnoremap <leader>f :Grepper -tool ag --vimgrep <CR>
