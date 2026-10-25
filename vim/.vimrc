set nocompatible
let mapleader=' ' "use space for leader key
" Cursor behaviour
autocmd InsertEnter,InsertLeave * set cul!
" General visual look of Vim
set number relativenumber
set noerrorbells
set visualbell
set laststatus=2
set showmode
set splitbelow splitright
set clipboard=unnamedplus
" Text searching options
set incsearch
set ignorecase
set smartcase
set showmatch
" Syntax and formatting
syntax on
set encoding=utf-8
set formatoptions=tcqrn1
set hidden
" Tabs and indenting
set smartindent
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set noshiftround
set scrolloff=3
" Command line completion options
set showcmd
set wildmenu
" Colors
set background=dark
let g:solarized_termcolors=256
let g:solarized_termtrans=1

" Remappings
" Exit insert mode by double tapping uppercase J
imap JJ <ESC>
" Autocomplete brackets and quotation marks
inoremap ( ()<ESC>hli
inoremap { {}<ESC>hli
inoremap [ []<ESC>hli
inoremap ' ''<ESC>hli
inoremap " ""<ESC>hli
inoremap ` ``<ESC>hli
" Don't exit visual mode after indenting
vnoremap > >gv
vnoremap < <gv

filetype on
filetype plugin on "required
filetype plugin indent on "required
