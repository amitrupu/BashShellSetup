echo Setting up BASH for $(uname -s) ...
echo : HOST: $HOSTNAME
echo : BASH: $BASH

# Common setups
# xset -r
set autolist
set show-all-if-ambiguous on
export vbell=off
export TERM=xterm-256color
export EDITOR=vim

# Prompt
SHORTPROMPT=0
export B_PATHREPLACEPATTERN='\/home\/$USER/\~'
# btitle '$HOSTNAME : $PWD'
btitle '$PWD'
if [ $SHORTPROMPT -eq 1 ]; then
    export B_PATHREPLACEPATTERN='*\//.../'
fi
function recolorprompt {
    local promptcolor=${1:-green}
    if [[ -n "$SGE_O_HOST" || -n "$LSB_HOSTS" ]]; then
        if [[ $HOSTNAME == *odc* ]]; then
            bprompt bold+$promptcolor 'pwd' '>>'
        else
            bprompt bold+$promptcolor 'pwd' '>>'
        fi
    else
        bprompt $promptcolor 'pwd' '>'
        # bprompt $promptcolor '\[$(tput bold)\]pwd' '>'
    fi
}
recolorprompt
if [ -n "$CTX_REMOTE_DISPLAY" ]; then
    export DISPLAY=$CTX_REMOTE_DISPLAY
fi
if [[ -r ~/.Xresources && -n "$DISPLAY" ]]; then
    xrdb -merge ~/.Xresources
fi
function recolor {
    local type=$1
    local fgs=("#4444ee" "#444444" "#6020cc")
    local bgs=("#ffffbf" "#eeeeee" "#ddffff")
    local i=$(shuf -i0-$((${#fgs[@]}-1)) -n1)
    local j=$(shuf -i0-$((${#bgs[@]}-1)) -n1)
    recolorprompt
    if [ -z "$type" ]; then
        bxtermcolor fg=${fgs[$i]} bg=${bgs[$j]}
    elif [ $type == fg ]; then
        bxtermcolor fg=${fgs[$i]}
    elif [ $type == bg ]; then
        bxtermcolor bg=${bgs[$j]}
    elif [ $type == reverse ]; then
        recolorprompt white
        bxtermcolor bg=${fgs[$i]} fg=${bgs[$j]}
    fi
}

# GitHub setup for password save
#   create file ~/.git-credentials with content:
#     https://<username>:<classic-personal-access-token>@github.com
#     Get classic personal access token from Settings->Developer Settngs
git config --global credential.helper store
# git config --global credential.helper cache
# To sync: git pull, to commit: git add; git commit -m ".."; git push

# Common aliases
balias ll 'ls -al' "list alternative"
balias cdt 'cd ~/scratch' "go to scratch area"
function search_replace {
    local search=${1?$FUNCNAME: error: specify search}
    local replace=${2?$FUNCNAME: error: specify replace}
    grep -RiIl "$search" | xargs sed -i "s/$search/$replace/g"
}
bhelp search_replace "search and replace"
function broken_links {
    local path=${1:-.}
    local delete=${2:-no}
    if [ $delete == delete ]; then
        delete=-delete
    else
        delete=
    fi
    find $path -xtype l $delete -print
}
function f {
    if [ "$#" -eq 1 ]; then
        root=.
        ext=$1
        follow=-follow
    else
        root=$1
        ext=$2
        follow=
    fi
    find $root/ -name "*.$ext" $follow
}


