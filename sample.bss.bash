echo Setting up BASH for $USER ...

SHORTPROMPT=1
export B_PATHREPLACEPATTERN='\/cygdrive\/d/D:'
btitle '$PWD'
if [ $SHORTPROMPT -eq 1 ]; then
    unset B_PATHREPLACEPATTERN
    export PROMPT_DIRTRIM=2
fi
bprompt green 'pwd' '>'
# bprompt green '\[$(tput bold)\]pwd' '>'

# GitHub setup for password save
git config --global credential.helper store
git config --global credential.helper cache

balias cdc cd "go to code directory"
function complete_cdc {
    complete_directory_path '~/Sandbox/${USER}_*_work'
    # complete_directory '~/Sandbox/${USER}_*_work' 'map[a-z0-9]*'
}
complete -o nospace -F complete_cdc cdc

function cdw {
    local dir=${1:-$DEVHOME/Work}
    cd $dir
}
bhelp cdw "go to work directory"
function complete_cdw {
    complete_directory_path '~/Work/*'
}
complete -o nospace -F complete_cdw cdw

# Cygwin porting for Perforce
function p4 {
    export PWD=$(cygpath -w -a .)
    command p4 $*
    export PWD=$(pwd)
}

