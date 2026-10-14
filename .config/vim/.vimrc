" Leader
nnoremap <SPACE> <Nop>
let mapleader = " "
let g:lasttab = 1

"===============================================================
" => Plugins (vim-plug) — https://github.com/junegunn/vim-plug
"===============================================================
call plug#begin('~/.vim/autoload/plugged')
  " File explorer (lazy-loaded)
  Plug 'preservim/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind', 'NERDTreeFocus'] }
  Plug 'liuchengxu/vim-which-key'
  " UI
  Plug 'catppuccin/vim', { 'as': 'catppuccin' }
  Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
  Plug 'ryanoasis/vim-devicons'
call plug#end()

" +explorer group mappings
nnoremap <leader>ef :NERDTreeFind<CR>
nnoremap <leader>et :NERDTreeToggle<CR>
nnoremap <leader>eo :NERDTreeFocus<CR>
