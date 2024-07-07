" 1. Install this as a plugin into your vim using pathogen on something like
" that. Or simply copy all the contents to your .vimrc
" 2. define a hotkey for jumping to a target under cursor, e.g. add following
" to your .vimrc to bind Ctrl+b for this:
"   map <C-b> :exec("BuckOpenTarget")<CR>


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

" Tries to map a:path in a form of repo//path/to into a real filepath on the
" filesytem
function BuckMapPath(path)
    let dspos = stridx(a:path, "//")
    if dspos == -1
        return a:path
    endif

    " TODO: Support user provided mapping through global vars.
    "       First, lookup there and then try to guess from current path

    let repo = strpart(a:path, 0, dspos) 
    let curfilepath = expand("%:p:h")

    let repopath = BuckGetRepoPathInGivenPath(curfilepath, repo)
    if repopath == ""
        1echow "Not aware of path for ".a:repo
        return ""
    endif

    return repopath."/".strpart(a:path, dspos+2)
endfunction

" Navigate to target a:name in the currently opened buffer
function NavigateToTarget(tname)
    call cursor(1,1)
    let linenum = search('name = "'.a:tname.'"')
    if linenum == 0
        3echow("target definition is not found in this file, it is probably constructed dynamically")
    endif
endfunction

" Open target under cursor in a new tab
function BuckOpenTarget()
    let target = BuckGetTarget(getline("."), col("."))
    if target == ""
        1echow "Not a target name"
        return
    endif

    let tpath = strpart(target, 0, stridx(target, ":"))
    let tname = strpart(target, stridx(target, ":")+1)
    
    if tpath == ""
        call NavigateToTarget(tname)
        return
    endif

    let tpath = BuckMapPath(tpath)
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
        1echow "No targets found at `".tpath."` =("
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
