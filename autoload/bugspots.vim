" version: 0.9.0
" author : wan <one_kkm@icloud.com>
" license: mit license
let s:save_cpo = &cpo
set cpo&vim


if !exists('g:bugspots_git_executable')
  let g:bugspots_git_executable = "git log -p --name-only --pretty=format:'.%ct %s' > log"
endif


function! bugspots#bugspots()
    let current_git_path = getcwd() . "/.git"
    if isdirectory(current_git_path)
        call MakeBufferBugSpots()
    else
        echohl ErrorMsg | echomsg "Git CurrentDirectry Not Find" | echohl None
    endif
endfunction


function! s:LogMaker()
    call system(g:bugspots_git_executable)
    let lines=readfile("log")
    let list_log = []
    for line in lines
        if line[0] == "."
            let dict = {}
            if "" !=#  matchstr(line, '\v(fix|close)\c')
                let dict["unix_ts"] = matchstr(line, '\v\d{10}', 0)
                call add(list_log, dict)
            endif
        elseif line !=# ""
            call add(list_log , line)
        endif
    endfor
    return s:LogFormatter(list_log)
endfunction


function! s:LogFormatter(ll)
    let tmp = []
    let result = []
    for var in a:ll
        if type(var) == type({})
            call add(tmp, {"unix_ts": var["unix_ts"]})
        else
            try
                let d = deepcopy(tmp[-1])
                let d["file"] = var
                call add(result, d)
            catch
            endtry
        endif
        unlet var
    endfor
    return result
endfunction


function! s:GetMinTimeStamp(ll)
    let d = a:ll[-1]
    return str2nr(d["unix_ts"])
endfunction


function! CreateHotSpots()
    let result = []
    let hotspots = {}
    let list_log = s:LogMaker()
    let min_time = s:GetMinTimeStamp(list_log)
    for var in list_log
        let t = 1.0 - ((localtime() - str2nr(var["unix_ts"])) / (localtime() - (min_time + 0.0)))
        let filename = var["file"]
        if has_key(hotspots, filename)
            let tmp = hotspots[filename]
            let hotspots[filename] = tmp + 1.0 / (1.0 + exp((-12.0 * t) + 12.0))
        else
            let hotspots[filename] = 1.0 / (1.0 + exp((-12.0 * t) + 12.0))
        endif
    endfor
    for line in items(hotspots)
        call add(result, printf(" * %-80s : %.10f", line[0], line[1]))
    endfor
    return result
endfunction


function! MakeBufferBugSpots()
    let hotspots = CreateHotSpots()
    exe "new __BugSpots__"
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    call append(0, " --- Vim-BugSpots version:0.9.0 ---")
    call append(2, hotspots)
    setlocal nomodifiable
    setlocal filetype=bugspots
    setlocal nowrap
    call BugSpotsSyntaxSetting()
    nnoremap <script> <silent> <buffer> q        :call <sid>BugSpotsClose()<CR>
    cabbrev  <script> <silent> <buffer> q        call <sid>BugSpotsClose()
    cabbrev  <script> <silent> <buffer> quit     call <sid>BugSpotsClose()
endfunction


function! BugSpotsSyntaxSetting()
    let b:current_syntax = 'bugspots'
    syn match BS '\v(Vim-BugSpots)'
    syn match BSHyphen '\v\s(---)'
    syn match BSAsterisk '\v(\s\*\s)'
    syn match BSBorder '\v\s\:\s'
    syn match BSValue '\v([0-9]+)\.([0-9]{10})'
    hi def link BSHyphen Delimiter
    hi def link BSAsterisk Constant
    hi def link BS StorageClass
    hi def link BSBorder Identifier
    hi def link BSValue Keyword
endfunction


function! s:BugSpotsBufferName(name)
    if bufwinnr(bufnr(a:name)) != -1
        exe bufwinnr(bufnr(a:name)) . "wincmd w"
        return 1
    else
        return 0
    endif
endfunction


function! s:BugSpotsClose()
    if s:BugSpotsBufferName("__BugSpots__")
        quit
        let deletefile = "__BugSpots__"
        call delete(deletefile)
    endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
