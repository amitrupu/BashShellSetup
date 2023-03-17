# BashShellSetup : Commands Setup
# File: BashShellSetup/BCommands.bash
# Author: Amit Roy amitrupu@gmail.com
# Date: 1-Feb-2021

[ ${B_DEBUG:=0} -gt 0 ] && echo $(BMsgPrefix) : Setting up bash commands ...

# Setup help
unset B_HELPTABLE
function _bhelp {
    local fileName=$1
    local lineNumber=$2
    local command=$3
    local help=$4
    local helpTable
    local useHash=0
    if [ -n "$command" -a -n "$help" ]; then
        [ -n "$B_HELPPREFIX" ] && help+=" (${B_HELPPREFIX}:$lineNumber)"
        B_HELPTABLE=$(echo "$B_HELPTABLE" | sed "s/\[$command\]=\"[^\"]*\"//")
        B_HELPTABLE+=" [$command]=\"$help\""
        return 0
    fi
    if [ ${BASH_VERSION%%.*} -ge 4 ]; then
        declare -A helpTable
        eval "helpTable=($B_HELPTABLE)"
        useHash=1
    fi
    # useHash=0
    if [ -n "$command" ]; then
        # show specific command help
        local help
        if [ $useHash -eq 1 ]; then
            help="${helpTable[$command]}"
        else
            help=${B_HELPTABLE##*\[$command\]=\"}
            help=${help%%\"*}
        fi
        if [ -n "$help" ]; then
            # printf "%-20s : %s\n" $command "$help"
            echo $help
        else
            echo bhelp: error: no help available for command $command.
            return 1
        fi
    else 
        # show all command help
        if [ $useHash -eq 1 ]; then
            for command in "${!helpTable[@]}"; do
                printf "%-20s : %s\n" $command "${helpTable[$command]}"
            done
        else
            help=$(echo $B_HELPTABLE | sed \
                    -e 's/^\[//' \
                    -e 's/"$//' \
                    -e 's/" \[/"/g' \
                    -e 's/]="/"/g' \
                    )
            local oldIFS="$IFS"
            IFS='"'
            local helpArray=( $help )
            IFS="$oldIFS"
            for ((i=0;i<${#helpArray[@]};i+=2)); do
                command=${helpArray[$i]}
                help=${helpArray[$i+1]}
                printf " %-20s : %s\n" $command "$help"
            done
        fi
    fi
}
function complete_bhelp {
    local commands=$(echo "$B_HELPTABLE" | sed -e "s/\]=\"[^\"]*\"//g" -e "s/\[//g")
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$commands" -- "${currentWord}") )
}
complete -F complete_bhelp bhelp
alias bhelp='_bhelp "$BASH_SOURCE" "$LINENO"'
bhelp bhelp 'show or sets command help'

# Setup terminal title
unset B_PATHREPLACEPATTERN
function btitle {
    local title=${1:-\$PWD}
    [ -n "$B_PATHREPLACEPATTERN" ] && title=${title/\$PWD/'${PWD/'$B_PATHREPLACEPATTERN'}'}
    [ ${B_DEBUG:=0} -gt 0 ] && echo $(BMsgPrefix) : Setting terminal title as $title ...
    PROMPT_COMMAND='echo -ne "\e]0;'$title'\a"'
}
bhelp btitle 'sets terminal title'

# Format and coloring
# Source: misc.flogisoft.com/bash/tip_colors_and_formatting
function bformat {
    local format=${1?$FUNCNAME: error: specify format}
    local color=${2?$FUNCNAME: error: specify color}
    local string=${3?$FUNCNAME: error: specify string}
    # Source: www.tldp.org/HOWTO/text/Bash-Prompt-HOWTO - 3.4
    local forPrompt=${4:-no}

    # configurations
    B_BASH_TPUT=no
    B_BASH_ESC="\033" # can be: \e or \033 \x1B

    local formatCode
    if [ ${BASH_VERSION%%.*} -ge 4 ]; then
        declare -A formatMap
        formatMap=([bold]=1 [dim]=2 [underlined]=4 [blink]=5 [reverse]=7)
        formatCode=${formatMap[$format]}
    else
        case $format in
            bold) formatCode=1 ;; dim) formatCode=2 ;;
            underlined) formatCode=4 ;; blink) formatCode=5 ;;
            reverse) formatCode=7 ;;
        esac
    fi
    if [[ "$format" != none && -z "$formatCode" ]]; then
        echo $FUNCNAME: error: no such format $format.
        return 1
    elif [ "$format" == reverse ]; then
        format=rev
    fi

    local colorCode
    if [ ${BASH_VERSION%%.*} -ge 4 ]; then
        declare -A colorMap
        colorMap=([black]=0 [red]=1 [green]=2 [yellow]=3 [blue]=4 [purple]=5 [cyan]=6 [white]=7)
        colorCode=${colorMap[$color]}
    else
        case $color in
            black) colorCode=0 ;; red) colorCode=1 ;;
            green) colorCode=2 ;; yellow) colorCode=3 ;;
            blue) colorCode=4 ;; purple) colorCode=5 ;;
            cyan) colorCode=6 ;; white) colorCode=7 ;;
        esac
    fi
    if [[ "$color" != none && -z "$colorCode" ]]; then
        echo $FUNCNAME: error: no such color $color.
        return 1
    fi

    if [ ${B_BASH_TPUT:-yes} == yes ]; then
        local escPrefix
        [ -z "$formatCode" ] || escPrefix="$escPrefix$(tput $format)"
        [ -z "$colorCode" ] || escPrefix="$escPrefix$(tput setaf $colorCode)"
        if [ -z "$escPrefix" ]; then
            echo $string
        else
            echo -e "$escPrefix$string$(tput sgr0)"
        fi
    else
        local escCode
        [ -z "$formatCode" ] || escCode="$escCode;$formatCode"
        [ -z "$colorCode" ] || escCode="$escCode;3$colorCode"
        escCode=${escCode/;}
        if [ -z "$escCode" ]; then
            echo $string
        elif [ $forPrompt == yes ]; then
            echo -e "\[$B_BASH_ESC[${escCode}m\]$string\[$B_BASH_ESC[0m\]"
        else
            echo -e "$B_BASH_ESC[${escCode}m$string$B_BASH_ESC[0m"
        fi
    fi
    return 0
}

# Setup prompt
# export PROMPT_DIRTRIM=3
function bprompt {
    local color=${1?$FUNCNAME: error: specify color}
    local prompt=${2?$FUNCNAME: error: specify prompt}
    local promptend=$3
    [ -n "$B_PATHREPLACEPATTERN" ] && prompt=${prompt/pwd/'${PWD/'$B_PATHREPLACEPATTERN'}'}
    prompt=${prompt/user/\\u}; prompt=${prompt/host/\\h}; prompt=${prompt/history/\\!}
    prompt=${prompt/pwd/\\w}; prompt=${prompt/date/\\d}; prompt=${prompt/time/\\@}
    [ ${B_DEBUG:=0} -gt 0 ] && echo $(BMsgPrefix) : Setting terminal prompt color as $color ...
    export PS1=$(bformat none $color "$prompt" yes)"$promptend "
    return 0
}
function complete_bprompt {
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "black red green yellow blue purple cyan white" \
                    -- "${currentWord}") )
    else
        COMPREPLY=( $(compgen -W "user host history pwd date time" -- "${currentWord}") )
    fi
}
complete -F complete_bprompt bprompt
bhelp bprompt 'sets terminal prompt color'

# Xterm coloring
function bxtermcolor {
    local pair
    for pair in "$@"; do
        local attribute=${pair%%=*}
        local color=${pair#*=}
        if [ ${BASH_VERSION%%.*} -ge 4 ]; then
            declare -A attrMap
            attrMap=([bg]=11 [fg]=10 [cursor]=12 [hlfg]=17 [hlbg]=19)
            attrCode=${attrMap[$attribute]}
        else
            case $attribute in
                bg) attrCode=11 ;; fg) attrCode=10 ;;
                cursor) attrCode=12 ;;
                hlfg) attrCode=17 ;; hlbg) attrCode=19 ;;
            esac
        fi
        if [ -z "$attrCode" ]; then
            echo $FUNCNAME: error: invalid xterm attrbute specified in $pair ...
            return 1
        fi
        echo Setting terminal $attribute color to $color ...
        echo -en "\e]$attrCode;$color\a"
    done
    return 0
}
bhelp bxtermcolor 'sets terminal colors'

# Setup sourcing
function bsource {
    local setupFile=${1?bsource: error: specify setup file path}
    while [ -n "$setupFile" ]; do
        local helpPrefix
        local skip=0
        if [[ $setupFile == *bss.*.bash ]]; then
            helpPrefix=${setupFile##*bss.}
            helpPrefix=${helpPrefix%%.bash}
            [ -r $setupFile -a -r $setupFile.skip ] && skip=1
            if [ $skip -ne 1 ]; then
                local envvar=${setupFile//*bss/bss}
                envvar=B_TRACKMOD_${envvar//./_}
                local lastModified=$(stat -c %Y $setupFile)
                if [[ -n "${!envvar}" && ${!envvar} -ge $lastModified ]]; then
                    skip=1
                else
                    eval export $envvar=$lastModified
                fi
            fi
        fi
        if [ -r $setupFile -a $skip -ne 1 ]; then
            local oldHelpPrefix=$B_HELPPREFIX
            [ -n "$helpPrefix" ] && export B_HELPPREFIX=$helpPrefix
            local oldtrap=$(trap -- 'echo b' ERR | sed -e 's/^trap -- //')
            if [ -n "$helpPrefix" ]; then
                trap 'echo Error in setup $B_HELPPREFIX line $LINENO.' ERR
            else
                trap 'echo Error in file $setupFile line $LINENO.' ERR
            fi
            [ ${B_DEBUG:=0} -gt 0 ] && echo sourcing $setupFile ...
            source $setupFile
            if [ ! -z "$oldtrap" ]; then
                trap $oldtrap
            else
                trap - ERR
            fi
            [ -n "$helpPrefix" ] && unset B_HELPPREFIX
            [ -n "$oldHelpPrefix" ] && export B_HELPPREFIX=$oldHelpPrefix
        fi
        shift
        setupFile=$1
    done
}
bhelp bsource "source setup files"

function bchpath {
    local var=${3:-PATH}
    local newValue=${1?$FUNCNAME: error: specify new value to add to $var}
    local replacePattern=${2:-}
    local varExport=${4:-export}
    local value=${!var}
    if [ -n "$replacePattern" ]; then
        value=$(echo $value | sed -e "s#[^:]*$replacePattern[^:]*##g" \
            -e "s/::/:/g" -e "s/^://g" -e "s/:$//g")
    fi
    if [ -z "$value" ]; then
        value="$newValue"
    else
        value="$newValue:$value"
    fi
    $varExport $var="$value"
}
bhelp bchpath "update variable (e.g. PATH) value with new path"

function baddpath {
    export BSS_PCL="-set,-var value,-replace value,-at_first,valuelist"
    bparsecommand "$*"
    local var=${BSS_PCL_var:-PATH}
    local newValue=${BSS_PCL?$FUNCNAME: error: specify new value to add to $var}
    local replacePattern=${BSS_PCL_replace:-}
    local value=${!var}
    if [ -n "$replacePattern" ]; then
        value=$(echo $value | sed -e "s#[^:]*$replacePattern[^:]*##g" \
            -e "s/::/:/g" -e "s/^://g" -e "s/:$//g")
    fi
    if [ -z "$value" ]; then
        value=$newValue
    elif [ -n "$BSS_PCL_at_first" ]; then
        value=$newValue:$value
    else
        value=$value:$newValue
    fi
    if [ -z "$BSS_PCL_set" ]; then
        export $var="$value"
    else
        $var="$value"
    fi
    unset $(compgen -v BSS_PCL)
}
bhelp baddpath "add variable (e.g. PATH) value with new path"

function boptpath {
    local var=${1:-PATH}
    local varExport=${2:-export}
    local value=${!var}
    if [ -z "$value" ]; then
        return
    fi
    local optValue=$(echo "{$value}" | sed -e 's/:/}:{/g')
    local oldIFS=$IFS
    IFS=:
    for v in $optValue; do
    	IFS="$oldIFS"
        optValue=$(echo $optValue | sed -e "s#$v##2g" ) #-e 's/ /:/g')
    done
    IFS="$oldIFS"
    optValue=$(echo $optValue | sed -e 's/}:{/:/g' -e 's/[{}]//g' -e s'/::*/:/g')
    $varExport $var="$optValue"
}
function complete_boptpath {
    local commands="PATH LD_LIBRARY_PATH"
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$commands" -- "${currentWord}") )
}
complete -F complete_boptpath boptpath
bhelp boptpath "optimize variable (e.g. PATH) values"

function bshowpath {
    local var=${1:-PATH}
    local value=${!var}
    if [ -z "$value" ]; then
        return
    fi
    local oldIFS=$IFS
    IFS=:
    echo "Variable $var values:"
    local i=1
    for v in $value; do
        echo $i: $v
        ((i++))
    done
    IFS="$oldIFS"
}
function complete_bshowpath {
    local commands="PATH LD_LIBRARY_PATH LM_LICENSE_FILE"
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$commands" -- "${currentWord}") )
}
complete -F complete_bshowpath bshowpath
bhelp bshowpath "show value variable (e.g. PATH) values"

# Setup unset and unsourcing
function bunset {
    local type=${1?$FUNCNAME: error: specify type: variable or alias}
    local name=${2?$FUNCNAME: error: specify name}
    local silent=${3:-no}
    local setup=$4
    local noerror=yes
    if [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        [[ -n "$setup" && ! -r "$setup" ]] && return 0
        [ ${B_DEBUG:=0} -gt 0 ] && echo $FUNCNAME: info: unsetting $type $name ...
        case $type in
            variable) [ ${name/*_PATH/PATH} != PATH ] && unset $name ;;
            alias) local check=$(alias | grep " $name=")
                if [ -n "$check" ]; then
                    unalias $name
                else
                    noerror=$silent
                    unset setup
                fi
                ;;
        esac
        if [ -n "$setup" ]; then
            local unsetcmd="bunset $type $name yes $setup"
            if [[ ! -r ~/start.bss.bash || \
                $(grep -c "$unsetcmd" ~/start.bss.bash) -eq 0 ]]; then
                echo $unsetcmd.skip >> ~/start.bss.bash
            fi
        fi
    fi
    if [ "$noerror" == no ]; then
        echo $FUNCNAME: error: no such $type $name ...
    fi
}
bhelp bunset "unset variable or alias"
function bunsource {
    local setupFile=${1?$FUNCNAME: error: specify setup file path}
    local line
    while read line; do
        local list type name
        if [ -z "$line" ]; then
            continue
        fi
        declare -a list=( $line END )
        if [ "${list[0]}" == export -a "${list[1]/*=*/=}" = '=' ]; then
            type=variable
            name=${list[1]%%=*}
        elif [ "${list[0]/*=*/=}" = '=' ]; then
            type=variable
            name=${list[0]%%=*}
        elif [ "${list[0]}" == alias -a "${list[1]/*=*/=}" = '=' ]; then
            type=alias
            name=${list[1]%%=*}
        elif [ "${list[0]}" == balias -a -n "${list[1]}" ]; then
            type=alias
            name=${list[1]}
        else
            unset type name
        fi
        [ -n "$type" ] && bunset $type $name yes $setupFile
    done < $setupFile
}
bhelp bunsource "unsource setup files"

# Setup sourcing setup
function bsetup {
    local option=$1
    local setups="${@:2}"
    local setup
    if [ -z "$option" -o "$option" == status ]; then
        for file in ~/bss.*.bash; do
            setup=${file##*bss.}
            setup=${setup%%.bash}
            if [ -r $file.skip ]; then
                echo $(bformat reverse none "$setup (skipped)")
            else
                echo $(bformat bold none $setup)
            fi
        done
        return 0
    fi
    if [ $option != edit -a $option != delete -a $option != skip -a $option != unskip ]; then
        echo $FUNCNAME: error: argument 1 would be edit, delete, status, skip or unskip
        return 1
    fi
    if [ -z "$setups" ]; then
        for file in ~/bss.*.bash; do
            file=${file##*bss.}
            file=${file%%.bash}
            setups+=" $file"
        done
        if [ $option == delete -o $option == unskip ]; then
            rm -f ~/start.bss.bash
        fi
    fi
    [ -z "$setups" ] && return 0
    setups=${setups# }
    local setupList=( $setups )
    for setup in "${setupList[@]}"; do
        local setupFile=~/bss.$setup.bash
        local skipFile=$setupFile.skip
        if [ $option == edit ]; then
            if [ ! -r $setupFile ]; then
                echo $FUNCNAME: info: creating new setup $setup ...
            else
                echo $FUNCNAME: info: editing new setup $setup ...
            fi
            [ -z "$EDITOR" ] && EDITOR=vim
            $EDITOR $setupFile
        elif [ ! -r $setupFile ]; then
            echo $FUNCNAME: error: no such setup $setup available ...
            return 1
        else
            if [ $option == unskip -a -r "$skipFile" ]; then
                echo $FUNCNAME: info: ${option}ing setup $setup ...
                rm -f $skipFile
            elif [ $option == skip -a ! -r "$skipFile" ]; then
                echo $FUNCNAME: info: ${option}ing setup $setup ...
                bunsource $setupFile
                touch $skipFile
            elif [ $option == delete ]; then
                bunsource $setupFile
                rm -f $setupFile $skipFile
                echo $FUNCNAME: info: deleting setup $setup ...
            fi
        fi
        bsource $setupFile
    done
}
bhelp bsetup "modify (edit, delete, status, skip or unskip) bash setups"
function complete_bsetup {
    local setupFiles=( ~/bss.*.bash )
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    local previousWord=${COMP_WORDS[COMP_CWORD-1]}
    if [ $previousWord == bsetup ]; then
        local options=edit
        [ -r "$setupFiles" ] && options+=" delete status skip unskip"
        COMPREPLY=( $(compgen -W "$options" -- "${currentWord}") )
    else
        local option=${COMP_WORDS[1]}
        local setups=""
        local file
        for file in "${setupFiles[@]}"; do
            [ $option == skip -a -r "$file.skip" ] && continue
            [ $option == unskip -a ! -r "$file.skip" ] && continue
            file=${file##*bss.}
            file=${file%%.bash}
            local i=2
            while [ $i -lt $COMP_CWORD ]; do
                [ $file == ${COMP_WORDS[$i]} ] && break
                let i++
            done
            [ $i -eq $COMP_CWORD ] && setups+=" $file"
        done
        setups=${setups# }
        COMPREPLY=( $(compgen -W "$setups" -- "${currentWord}") )
    fi
}
complete -F complete_bsetup bsetup

# Directory completion by name
function complete_directory {
    local pathPattern=${1?}
    local namePattern=${2?}
    local withBraketPat=$(expr match "$namePattern" '.*\(([^()]*)\)')
    if [ -z "$withBraketPat" ]; then
        namePattern=".*\\($namePattern\\)"
    else
        namePattern="${namePattern/\\\(/(}"
        namePattern="${namePattern/\\)/)}"
        namePattern="${namePattern/\(/\\(}"
        namePattern="${namePattern/)/\\)}"
    fi
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    local file
    local paths=""
    for file in $(eval "ls -d $pathPattern"); do
        paths+=" "$(expr ${file##*/} : "$namePattern")
    done
    paths=${paths# }
    COMPREPLY=( $(compgen -W "$paths" -- "${currentWord}") )
}
# example
if [ -n "" ]; then
alias cdc=cd
function complete_cdc {
    complete_directory '$DEVHOME/Sandbox/amitroy_*_work*' \
        '[^_]*_([a-z0-9._]*)_work'
    # complete_directory '/cygdrive/d/Sandbox/amitroy_*_work' 'map[a-z0-9]*'
}
complete -F complete_cdc cdc
fi

# Directory completion by path
function complete_directory_path {
    local pathPattern=${1?}
    local currentWord=${COMP_WORDS[COMP_CWORD]}
    local file
    local paths=$(eval "ls -d $pathPattern")
    COMPREPLY=( $(compgen -S/ -W "$paths" -- "${currentWord}") )
    if [ ${#COMPREPLY[@]} -eq 0 ]; then
        COMPREPLY=( $(compgen -S/ -d "${currentWord}" ) )
    fi
}
# example
if [ -n "" ]; then
alias cdc=cd
function complete_cdc {
    complete_directory_path '/cygdrive/d/Sandbox/amitroy_*_work'
}
complete -o nospace -F complete_cdc cdc
fi

# Setup for switching current directories
bssCd=~/.bss.cdirs
function scd {
    local name=${1:-default}
    local dir=${2:-$(pwd)}
    sed -i "/^$name=.*/d" $bssCd
    if [[ "$dir" == delete || "$dir" == none ]]; then
        echo deleting $name
    else
        echo $name=$dir
        echo $name=$dir >> $bssCd
    fi
}
bhelp scd "set current directory (delete|none to delete)"
function ccd {
    local name=${1:-default}
    local dir=$(grep -e "^$name=" $bssCd | cut -d = -f 2)
    cd $dir
}
bhelp ccd "change to latest or specified current directory"
function complete_ccd {
    local word=${COMP_WORDS[COMP_CWORD]}
    local names=$(sort $bssCd | cut -d = -f 1)
    COMPREPLY=( $(compgen -W "$names" -- "${word}") )
}
complete -o nospace -F complete_ccd ccd
function lcd {
    local clean=$1
    if [[ -n "$clean" && "$clean" == clean ]]; then
        echo cleaning ...
        local isberry=
        if [ -r /berry/berryhome ]; then
            isberry=yes
        fi
        local pair=
        for pair in $(cat $bssCd); do
            local name=${pair%%=*}
            local path=${pair#*=}
            if [ ! -d $path ]; then
                if [[ -z "$isberry" && $path == /berry/* ]]; then
                    continue
                fi
                echo cleaning $name=$path
                sed -i "/^$name=.*/d" $bssCd
            fi
        done
        return
    fi
    sort $bssCd
}
bhelp lcd "list all current directories"

# Setup alias
function _balias {
    local aliasName=${3?$FUNCNAME: error: specify alias name}
    local aliasCommand=${4?$FUNCNAME: error: specify alias command}
    local aliasHelp=${5?$FUNCNAME: error: specify alias help}
    eval "alias $aliasName='$aliasCommand'"
    _bhelp $1 $2 $aliasName "$aliasHelp"
}
alias balias='_balias "$BASH_SOURCE" "$LINENO"'
bhelp balias "creates alias with help"

# Setup confirm before execute
function bconfirm {
    local command=${*?$FUNCNAME: error: specify alias command}
    echo -n "confirm execution of [ $command ] : (y/n) "
    local option
    read option
    if [[ "${option,,}" =~ ^y(es)?$ ]]; then
        eval "$command"
    fi
}

# Setup execute
function bexec {
    local execFile=${1?$FUNCNAME: error: specify executable path}
    shift
    if [ ! -r $execFile ]; then
        echo $FUNCNAME: error: no such file $execFile
        return
    fi
    $execFile $*
}
bhelp bexec "execute command line"

# Command line parsing - options should be specified in BSS_PCL
# * to use, call: export BSS_PCL="-opt1,-opt2 value,valuelist"
# * after processing BSS_PCL_*, call: unset $(compgen -v BSS_PCL)
function bparsecommand {
    if [ -z "$BSS_PCL" ]; then
        echo Error: missing environment BSS_PCL=\"-opt1,-opt2 value,valuelist\" ...
        return 1
    fi
    local opt
    local lastopt
    local values=""
    BSS_PCL=",$BSS_PCL,"
    for opt in $*; do
        if [ ${opt:0:1} == '-' ]; then
            if [[ $BSS_PCL != *",$opt,"* && $BSS_PCL != *",$opt "* ]]; then
                echo Error: invalid option $opt ...
                return 1
            fi
            if [ -n "$lastopt" ]; then
                if [[ $BSS_PCL == *",$lastopt value,"* ]]; then
                    echo Error: value expected for $lastopt ...
                    return 1
                fi
                export "BSS_PCL_${lastopt/-/}"=1
            fi
            lastopt=$opt
        else
            if [ -n "$lastopt" ]; then
                if [[ $BSS_PCL == *",$lastopt value,"* ]]; then
                    export "BSS_PCL_${lastopt/-/}"="$opt"
                elif [[ $BSS_PCL != *",valuelist,"* ]]; then
                    echo Error: invalid value $opt without option ...
                    return 1
                else
                    export "BSS_PCL_${lastopt/-/}"=1
                    values+=" $opt"
                fi
            elif [[ $BSS_PCL != *",valuelist,"* ]]; then
                echo Error: invalid value $opt without option ...
                return 1
            else
                values+=" $opt"
            fi
            unset lastopt
        fi
    done
    if [[ $BSS_PCL == *",$lastopt value,"* ]]; then
        echo Error: value expected for $lastopt ...
        return 1
    fi
    if [ -n "$lastopt" ]; then
        export "BSS_PCL_${lastopt/-/}"=1
    fi
    if [ -n "$values" ]; then
        export BSS_PCL="${values# }"
    else
        unset BSS_PCL
    fi
    return 0
}
bhelp bparsecommand "parse command line"

# Disk status
function bdiskstat {
    local dir=${1?FUNCNAME: error: specify directory}
    local summary=${2:-1}
    # local trim=${3:--0}
    local trim=${3:-10}
    if [ ! -d $dir ]; then
        echo $FUNCNAME: error: $dir does not exist ...
        return
    fi
    df -h $dir
    if [ $summary -eq 1 ]; then
        eval "du -sh $dir/*" | sort -rh | head --lines=$trim
    else
        du -Sh $dir | sort -rh | head --lines=$trim
    fi
}
bhelp bdiskstat "disk status"

# XTerm
function bxterm {
    if [[ $(uname -s) == CYGWIN* ]]; then
        mintty
        return
    fi
    local size=${1:-100x30}
    local pos=${2:-+0+0}
    local opts=$3
    local font="-fa Monospace -fs 11"
    # -fn "-b&h-lucidatypewriter-medium-r-normal-sans-16-*"
    xterm $font -geometry $size$pos $opts
}
bhelp bxterm "open X terminal window"
balias x 'bxterm &' "open terminal window"
# balias x 'bxterm -rv &' "open terminal window"

function btargz {
    local tgz=${1:-BashShellSetup.tgz}
    # [ "${tgz%/*}" == $tgz ] && tgz="$PWD/$tgz"
    tar --exclude=CVS -cvzf $tgz -C $B_ROOT/.. ${B_ROOT##*/}
}
bhelp btargz "create tar-gz backup of BashShellSetup"

# Quick aliases
balias i 'source ~/.bashrc' "restart bash"
balias c clear "clear terminal"
balias q exit "exit"
balias l 'ls --color=auto -al' "list files in details"
balias md 'mkdir -p' "make directory alterative"
balias path 'readlink -f' "find absolute path canonicalizing symbolic links"

# END
