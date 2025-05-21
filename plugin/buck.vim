" Global variable to store repository mappings
let g:buck_repositories = {}


function BuckDetectLeftTargetPos(line, pos)
    let left = a:pos
    let curpos = a:pos
    while curpos>0
        let ch = a:line[curpos]
        if index([' ', '@', '(', '"'], ch) != -1
            return left
        endif
        let left = curpos
        let curpos -= 1
    endwhile

    return left
endfunction

function BuckDetectRightTargetPos(line, pos)
    let right = a:pos
    let curpos = a:pos
    while curpos <= len(a:line)
        let ch = a:line[curpos]
        if index([' ', ')', '"'], ch) != -1
            return right
        endif
        let right = curpos
        let curpos += 1
    endwhile

    return right
endfunction

" Try to find a target in form of repo//path/to:target in given a:line
" with cursor starting at a:pos
function BuckGetTarget(line, pos)
    let left = BuckDetectLeftTargetPos(a:line, a:pos)
    let right = BuckDetectRightTargetPos(a:line, a:pos)
    if left == -1 || right == -1
        return ""
    endif

    let target = strpart(a:line, left, right-left+1)

    if stridx(target, ":") == -1
        return ""
    endif

    return target
endfunction

" Tries to guess a:repo path from a:givenpath
function BuckGetRepoPathInGivenPath(givenpath, repo)
    let repopos = stridx(a:givenpath, a:repo)
    if repopos == -1
        return ""
    endif

    return strpart(a:givenpath, 0, repopos+len(a:repo))
endfunction

function! BuckLoadConfig()
  " Try to find .buckconfig in current or parent directories
  let l:buckconfig_path = findfile('.buckconfig', '.;')
  if empty(l:buckconfig_path)
    return
  endif

  " Read the file
  let l:lines = readfile(l:buckconfig_path)
  let l:buckconfig_path = trim(system('dirname '. l:buckconfig_path))

  " Parse the file
  let l:current_section = ''
  for l:line in l:lines
    " Skip empty lines and comments
    if l:line =~ '^\s*$' || l:line =~ '^\s*[#;]'
      continue
    endif

    " Section header [section]
    let l:section_matches = matchlist(l:line, '^\s*\[\(.*\)\]\s*$')
    if !empty(l:section_matches)
      let l:current_section = l:section_matches[1]
      continue
    endif


    " Key-value pair
    if l:line =~ '^\s*\([^=]*\)=\(.*\)$' && l:current_section ==? 'repositories'
        let l:parts = split(l:line, '=', 1)
        if len(l:parts) >= 2
            " Trim whitespace from key and value
            let l:key = substitute(l:parts[0], '^\s*\|\s*$', '', 'g')
            let l:value = substitute(join(l:parts[1:], '='), '^\s*\|\s*$', '', 'g')
            let l:value = substitute(l:value, './', l:buckconfig_path.'/', '')
            let g:buck_repositories[l:key] = l:value
        endif
    endif
  endfor
endfunction
command! BuckReloadConfig call BuckLoadConfig()

" Tries to map a:path in a form of repo//path/to into a real filepath on the
" filesytem
function BuckMapPath(path, verbose)
    let dspos = stridx(a:path, "//")
    if dspos == -1
        return a:path
    endif

    let repo = strpart(a:path, 0, dspos) 
    " get buck root if repo is empty. Otherwise try to determine its path
    let repopath = ""
    let curfilepath = expand("%:p:h")
    if repo == ""
        let repopath = trim(system('buck2 root --dir ' . curfilepath))
        if repopath == ""
            echoerr "Can't find buck root"
        endif
    else
        if empty(g:buck_repositories)
            call BuckLoadConfig()
        endif
        " If we have this repository in our mappings, use it
        if has_key(g:buck_repositories, repo)
            let repopath = g:buck_repositories[repo]
        else
            let repopath = BuckGetRepoPathInGivenPath(curfilepath, repo)
        endif
    endif

    if repopath == ""
        if a:verbose
            echoerr "Not aware of path for ".a:repo
        endif
        return ""
    endif

    return repopath."/".strpart(a:path, dspos+2)
endfunction

" Navigate to target a:name in the currently opened buffer
function NavigateToTarget(tname)
    call cursor(1,1)
    let linenum = search('name = "'.a:tname.'"')
    if linenum == 0
        echoerr "target definition is not found in this file, it is probably constructed dynamically"
    endif
endfunction

" Open target under cursor in a new tab
function BuckOpenTarget()
    let target = BuckGetTarget(getline("."), col("."))
    if target == ""
        echoerr "Not a target name"
        return
    endif

    let tpath = strpart(target, 0, stridx(target, ":"))
    let tname = strpart(target, stridx(target, ":")+1)

    if tpath == ""
        call NavigateToTarget(tname)
        return
    endif

    let tpath = BuckMapPath(tpath, 1)
    if tpath == ""
        return
    endif

    let filename=""
    if filereadable(tpath."/TARGETS")
        let filename = tpath."/TARGETS"
    elseif filereadable(tpath."/BUCK")
        let filename = tpath."/BUCK"
    endif

    if filename != ""
        execute "silent! tabnew ".filename
        call NavigateToTarget(tname)
    else
        echoerr "No targets found at `".tpath."` =("
    endif
endfunction
command BuckOpenTarget call BuckOpenTarget()

" Tests
let v:errors = []

call assert_equal("", BuckGetTarget('    "$(location fbcode//path/to:mytarget)",', 12))
call assert_equal("fbcode//path/to:mytarget", BuckGetTarget('    "$(location fbcode//path/to:mytarget)",', 20))
call assert_equal("fbcode//path/to:mytarget", BuckGetTarget('    "$(location fbcode//path/to:mytarget)",', 34))
call assert_equal("/path_to/fbcode", BuckGetRepoPathInGivenPath("/path_to/fbcode/path/to/target", "fbcode"))

echohl WarningMsg
for err in v:errors
  echo err
endfor
echohl None
