" =============================================================================
" File:          plugin/vim-live.vim
" Description:   Manage LiveBrowser instances right from within vim
" Author:        Luis Fung <github.com/fungl164>
" License:       Copyright (C) 2014 Luis Fung
"                Released under MIT
" =============================================================================

" USAGE:        LiveBrowserOpen [url]
"               LiveBrowserClose
"
" TODO:         Add remote debugger management
"               Add remote tab/window management
"               Test Linux & windows
"
if exists("loaded_vim_live")
    finish
endif
let loaded_vim_live = 1

let s:browser_args = " --no-first-run
            \  --no-default-browser-check
            \  --allow-file-access-from-files
            \  --temp-profile
            \  --user-data-dir=/tmp
            \  --remote-debugging-port=9222"

let s:browser_app_unix   = system('uname')=~'Darwin' ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : 'google-chrome'
let s:browser_pids_unix  = "ps aux | grep -ie remote-debugging-port=9222 | awk '!/grep/ {print $2}'"

let s:browser_app_win32  = 'chrome.exe'
let s:browser_pids_win32 = "for /f \"tokens=4,1*skip=1\" %i in (\'wmic process where \"caption=\'chrome.exe\' AND commandline like \'%%remote-debugging-port=9222%%\'\" get ProcessId\') do @echo %i"

function! s:Init()
    if has('win32')
        let s:browser_app  = s:browser_app_win32                        " Windows
        let s:browser_pids = s:browser_pids_win32
        let s:browser_kill = 'taskkill /PID '
    elseif has('unix')
        let s:browser_app  = s:browser_app_unix                         " OSX or Linux
        let s:browser_pids = s:browser_pids_unix
        let s:browser_kill = 'kill -15 '
    endif
endfunction
call s:Init()

function! s:OpenBrowser(url)
    if exists('g:live-browser')
        let s:browser_app = g:live-browser                              " User-defined (determined at runtime)
    endif
    if !s:IsBrowserRunning()
        silent exe "!'".s:browser_app."' ".s:browser_args." ".a:url." > /dev/null 2>&1 &" | redraw!
    endif
endfunction

function! s:CloseBrowser()
    let l:pids = s:GetBrowserPids()
    if len(l:pids) > 0
        silent call system(s:browser_kill.' '.l:pids[0]) | redraw!
    endif
endfunction

function! s:IsBrowserRunning()
    return len(s:GetBrowserPids()) > 0 ? 1 : 0
endfunction

function! s:GetBrowserPids()
    return split(system(s:browser_pids))
endfunction

" Register Commands
command! -nargs=? LiveBrowserOpen  :call s:OpenBrowser(<f-args>)
command! -nargs=0 LiveBrowserClose :call s:CloseBrowser()
