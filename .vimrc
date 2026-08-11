" Personal Vim configuration.
" Target: Vim 9+, macOS. Leader key: Space.

set nocompatible
let mapleader = ' '

" -----------------------------------------------------------------------------
" Editor
" -----------------------------------------------------------------------------

filetype plugin indent on
syntax enable

set number
set cursorline
set shiftwidth=4
set tabstop=4
set expandtab
set nobackup
set autowriteall
set scrolloff=10
set nowrap
set incsearch
set ignorecase
set smartcase
set showcmd
set showmode
set showmatch
set hlsearch
set history=1000
set wildmenu
set wildmode=list:longest
set wildignore+=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
set updatetime=300
set signcolumn=yes
set laststatus=2

if has('clipboard')
    " Use the macOS clipboard for regular y/p operations.
    set clipboard=unnamed
endif

" True color — kitty supports 24-bit; required for modern colorschemes.
if has('termguicolors')
    set termguicolors
endif

if has('gui_running')
    set guifont=IBM\ Plex\ Mono:h13
endif

augroup vim_filetype
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" -----------------------------------------------------------------------------
" Plugins (vim-plug)
" -----------------------------------------------------------------------------

let s:vim_plug = expand('~/.vim/autoload/plug.vim')
if filereadable(s:vim_plug)
    call plug#begin('~/.vim/plugged')

    " File tree.
    Plug 'preservim/nerdtree'

    " Rust and TOML support.
    Plug 'cespare/vim-toml', { 'branch': 'main' }
    Plug 'rust-lang/rust.vim'

    " LSP client; language extensions are installed through :CocInstall.
    Plug 'neoclide/coc.nvim', { 'branch': 'release' }

    " Fuzzy search for files, buffers, history and symbols.
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Test runner and Git hunk navigation.
    Plug 'vim-test/vim-test'
    Plug 'airblade/vim-gitgutter'

    " Colorscheme.
    Plug 'morhetz/gruvbox'

    " Status line.
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    " Filetype icons (must be loaded after all other plugins).
    Plug 'ryanoasis/vim-devicons'

    call plug#end()
else
    echohl WarningMsg
    echom 'vim-plug not found: install ~/.vim/autoload/plug.vim'
    echohl None
endif
unlet s:vim_plug

" Plugin settings.
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0

let NERDTreeIgnore = ['\.git$', '\.jpg$', '\.mp4$', '\.ogg$', '\.iso$',
      \ '\.pdf$', '\.pyc$', '\.odt$', '\.png$', '\.gif$', '\.db$']

let test#strategy = 'vimterminal'
let test#vim#term_position = 'belowright 15'

" Airline: status/tabline with git branch, coc diagnostics, gruvbox theme.
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#coc#enabled = 1

" vim-devicons: Nerd Font glyphs in NERDTree, airline, fzf.
let g:webdevicons_enable = 1
let g:webdevicons_enable_nerdtree = 1
let g:webdevicons_enable_airline_tabline = 1

" Gruvbox colorscheme — applied after plug#end() so the plugin is on &rtp.
let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_invert_selection = 0
set background=dark
silent! colorscheme gruvbox

" -----------------------------------------------------------------------------
" General mappings
" -----------------------------------------------------------------------------

inoremap jj <Esc>
nnoremap <F3> :set hlsearch!<CR>
nnoremap <F5> :NERDTreeToggle<CR>

" Find: files, recent files and open buffers.
nnoremap <silent> <leader>ff :Files<CR>
nnoremap <silent> <leader>fe :History<CR>
nnoremap <silent> <leader>fb :Buffers<CR>

" Tests: nearest, file, last command, suite, suite with one failure retry.
nnoremap <silent> <leader>tn :TestNearest<CR>
nnoremap <silent> <leader>tf :TestFile<CR>
nnoremap <silent> <leader>tl :TestLast<CR>
nnoremap <silent> <leader>ts :TestSuite<CR>
nnoremap <silent> <leader>tr :TestSuite -Dsurefire.rerunFailingTestsCount=1<CR>

" Git hunks: navigation, preview, stage and undo.
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)
nmap <leader>gp <Plug>(GitGutterPreviewHunk)
nmap <leader>gs <Plug>(GitGutterStageHunk)
nmap <leader>gu <Plug>(GitGutterUndoHunk)

" -----------------------------------------------------------------------------
" CoC / LSP
" -----------------------------------------------------------------------------

function! CheckBackspace() abort
    let l:column = col('.') - 1
    return !l:column || getline('.')[l:column - 1] =~# '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

inoremap <silent><expr> <CR> coc#pum#visible()
      \ ? coc#pum#confirm()
      \ : "\<C-g>u\<CR>\<C-r>=coc#on_enter()\<CR>"

if has('nvim')
    inoremap <silent><expr> <C-Space> coc#refresh()
else
    inoremap <silent><expr> <C-@> coc#refresh()
endif

function! ShowDocumentation() abort
    if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
    else
        call feedkeys('K', 'in')
    endif
endfunction

nnoremap <silent> K :call ShowDocumentation()<CR>

" Scroll CoC floating windows; preserve normal Vim behavior otherwise.
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(1)\<CR>" : "\<Right>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(0)\<CR>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

" Navigation.
nnoremap <silent> gd :call CocActionAsync('jumpDefinition')<CR>
nnoremap <silent> gy :call CocActionAsync('jumpTypeDefinition')<CR>
nnoremap <silent> gi :call CocActionAsync('jumpImplementation')<CR>
nnoremap <silent> gr :call CocActionAsync('jumpReferences')<CR>
nnoremap <silent> [g :call CocActionAsync('diagnosticPrevious')<CR>
nnoremap <silent> ]g :call CocActionAsync('diagnosticNext')<CR>

" Code actions and project search.
nmap <silent> <leader>ca <Plug>(coc-codeaction-cursor)
nmap <silent> <leader>cs <Plug>(coc-codeaction-source)
nnoremap <leader>cr :call CocActionAsync('rename')<CR>
nnoremap <leader>ci :call CocActionAsync('organizeImport')<CR>
nnoremap <leader>cf :call CocActionAsync('format')<CR>
nnoremap <silent> <leader>co :<C-u>CocList outline<CR>
nnoremap <silent> <leader>dd :<C-u>CocList diagnostics<CR>
nnoremap <silent> <leader>fs :<C-u>CocList -I symbols<CR>

" -----------------------------------------------------------------------------
" Autosave
" -----------------------------------------------------------------------------

let g:autosave_idle_timer = -1

function! AutoSaveBuffer() abort
    if &buftype ==# '' && &modifiable && !&readonly && !empty(bufname('%'))
        silent update
    endif
endfunction

function! AutoSaveAfterIdle(timer_id) abort
    let g:autosave_idle_timer = -1
    call AutoSaveBuffer()
endfunction

function! ScheduleAutoSave() abort
    if &buftype !=# '' || !&modifiable || &readonly || empty(bufname('%'))
        return
    endif

    if g:autosave_idle_timer != -1
        call timer_stop(g:autosave_idle_timer)
    endif
    let g:autosave_idle_timer = timer_start(5000, function('AutoSaveAfterIdle'))
endfunction

function! AutoSaveOnLeave() abort
    if g:autosave_idle_timer != -1
        call timer_stop(g:autosave_idle_timer)
        let g:autosave_idle_timer = -1
    endif
    call AutoSaveBuffer()
endfunction

augroup autosave
    autocmd!
    autocmd FocusLost,BufLeave * call AutoSaveOnLeave()
    if exists('*timer_start')
        autocmd TextChanged,TextChangedI * call ScheduleAutoSave()
    endif
augroup END

" -----------------------------------------------------------------------------
" macOS keyboard layout
" -----------------------------------------------------------------------------

" If macism is installed, Normal mode always uses the English layout.
if executable('macism')
    augroup keyboard_layout
        autocmd!
        autocmd VimEnter,InsertLeave * call system('macism com.apple.keylayout.ABC')
    augroup END
endif

" -----------------------------------------------------------------------------
" Java and Maven
" -----------------------------------------------------------------------------

function! ConfigureJavaMake() abort
    let l:wrapper = findfile('mvnw', '.;')
    let l:wrapper_path = empty(l:wrapper) ? '' : fnamemodify(l:wrapper, ':p')
    if !empty(l:wrapper_path) && executable(l:wrapper_path)
        let &l:makeprg = fnameescape(l:wrapper_path)
    else
        let &l:makeprg = 'mvn'
    endif

    setlocal errorformat=
          \%E[ERROR]\ %f:[%l\\,%v]\ %m,
          \%E[ERROR]\ %f:[%l]\ %m,
          \%W[WARNING]\ %f:[%l\\,%v]\ %m,
          \%-G[INFO]\ %.%#,
          \%-G%.%#
endfunction

augroup java_make
    autocmd!
    autocmd FileType java call ConfigureJavaMake()
augroup END

" Create a Java class or a minimal JUnit test in an empty new buffer.
function! NewJavaFile() abort
    if !(line('$') == 1 && getline(1) ==# '')
        return
    endif

    let l:directory = expand('%:p:h')
    let l:package = ''
    for l:root in ['src/main/java', 'src/test/java']
        let l:index = stridx(l:directory, l:root)
        if l:index >= 0
            let l:relative = strpart(l:directory, l:index + strlen(l:root))
            let l:package = substitute(substitute(l:relative, '^/', '', ''), '/', '.', 'g')
            break
        endif
    endfor

    let l:class = expand('%:t:r')
    let l:lines = []
    if !empty(l:package)
        call add(l:lines, 'package ' . l:package . ';')
        call add(l:lines, '')
    endif

    if l:class =~? 'Test$'
        call extend(l:lines, [
              \ 'import org.junit.jupiter.api.Test;',
              \ '',
              \ 'class ' . l:class . ' {',
              \ '',
              \ '    @Test',
              \ '    void test() {',
              \ '    }',
              \ '}'
              \ ])
        let l:cursor_line = index(l:lines, '    void test() {') + 1
    else
        call extend(l:lines, [
              \ 'public class ' . l:class . ' {',
              \ '}'
              \ ])
        let l:cursor_line = len(l:lines)
    endif

    call setline(1, l:lines[0])
    if len(l:lines) > 1
        call append(1, l:lines[1:])
    endif
    call cursor(l:cursor_line, l:class =~? 'Test$' ? 9 : 1)
endfunction

augroup java_templates
    autocmd!
    autocmd BufNewFile *.java call NewJavaFile()
augroup END

nnoremap <leader>jn :call NewJavaFile()<CR>

" Toggle between Maven production and test source files.
function! JavaToggleTest() abort
    let l:file = expand('%:p')
    if l:file !~# '\.java$'
        echohl WarningMsg | echo 'not a Java file' | echohl None
        return
    endif

    if l:file =~# '/src/main/java/'
        let l:target = substitute(l:file, '/src/main/java/', '/src/test/java/', '')
        let l:target = substitute(l:target, '\.java$', 'Test.java', '')
    elseif l:file =~# '/src/test/java/' && l:file =~# 'Test\.java$'
        let l:target = substitute(l:file, '/src/test/java/', '/src/main/java/', '')
        let l:target = substitute(l:target, 'Test\.java$', '.java', '')
    else
        echohl WarningMsg | echo 'file is outside Maven main/test source roots' | echohl None
        return
    endif

    execute 'edit' fnameescape(l:target)
endfunction

nnoremap <leader>jt :call JavaToggleTest()<CR>

" Run Maven commands in a bottom terminal. Prefer the project wrapper.
function! MavenRun(target) abort
    if findfile('pom.xml', '.;') ==# ''
        echohl WarningMsg | echo 'pom.xml not found' | echohl None
        return
    endif

    let l:wrapper = findfile('mvnw', '.;')
    let l:wrapper_path = empty(l:wrapper) ? '' : fnamemodify(l:wrapper, ':p')
    if !empty(l:wrapper_path) && executable(l:wrapper_path)
        let l:command = [l:wrapper_path, a:target]
    elseif executable('mvn')
        let l:command = ['mvn', a:target]
    else
        echohl WarningMsg | echo 'Maven executable not found' | echohl None
        return
    endif

    belowright 15 new
    call term_start(l:command, {
          \ 'curwin': 1,
          \ 'term_name': 'maven ' . a:target
          \ })
endfunction

nnoremap <silent> <leader>mr :call MavenRun('spring-boot:run')<CR>
nnoremap <silent> <leader>mt :call MavenRun('test')<CR>
nnoremap <silent> <leader>mv :call MavenRun('verify')<CR>

" -----------------------------------------------------------------------------
" Private and machine-local overrides
" -----------------------------------------------------------------------------

" Keep credentials, corporate URLs and machine-specific SDK paths in this
" untracked file instead of committing them to the public repository.
let s:local_vimrc = expand('~/.vimrc.local')
if filereadable(s:local_vimrc)
    execute 'source ' . fnameescape(s:local_vimrc)
endif
unlet s:local_vimrc
