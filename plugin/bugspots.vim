" version: 0.9.0
" author : wan <one_kkm@icloud.com>
" license: mit license

if exists("g:loaded_bugspots")
  finish
endif
let g:loaded_bugspots = 1
let s:save_cpo = &cpo
set cpo&vim

command! Bugspots call bugspots#bugspots()
command! Test call bugspots#LogMaker()

let &cpo = s:save_cpo
unlet s:save_cpo
