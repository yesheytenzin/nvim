" The templ filetype lives here, not init.lua: a top-level vim.filetype.add()
" pulls the vim.filetype module into startup (~0.8ms). ftdetect scripts are
" sourced lazily the first time filetype detection runs instead.
autocmd BufNewFile,BufRead *.templ setfiletype templ
