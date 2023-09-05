# BashShellSetup : Main Setup
# File: BashShellSetup/BSetup.bash
# Author: Amit Roy amitrupu@gmail.com
# Date: 05-Sep-2023

# Skip sourcing rest of bashrc when called not interactively,
# i.e. from scp/rsync
case $- in
    *i*) ;;
      *) return;;
esac

# Skip sourcing from within gdb
if [[ "$SHELL" != *bash$ ]]; then
    export SHELL=/bin/bash
fi
if [[ "$(ps -o command= -p $PPID)" == gdb* ]]; then
    echo Skipping .basrc from with gdb ...
    return
fi

set +x

# Restore initial BASH environment
if [ -z "$PATH" ]; then
    export PATH=/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin
fi
if [ -z "$B_ROOT" ]; then
    echo Saving initial BASH environment ...
    env | grep -vi path > ~/.bss.env
elif [ -r ~/.bss.env ]; then
    export $(grep -v ' \|HOST' ~/.bss.env)
    export PATH=${PATH}:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin
fi
if [ -z "$SSH_CONNECTION" ]; then
    rm -f ~/.bss.env
fi
if [ -n "$SGE_O_SHELL" ]; then
    rm -f ~/.bss.env
fi

# Installation name and message prefix setup
[ -e ~/.bss.root ] && source ~/.bss.root
[ -z "$B_ROOT" ] && B_ROOT=~/BashShellSetup
function BMsgPrefix {
    echo Bash Shell Setup
}

# Debug setup
# B_DEBUG=1
[ -r ~/BSS_DEBUG ] && B_DEBUG=1
[ ${B_DEBUG:=0} -gt 0 ] && echo $(BMsgPrefix) : Setting up Bash ...

# General shell setup
shopt -s checkwinsize
shopt -s extglob

# History setups
export HISTCONTROL="erasedups:ignoreboth"
shopt -s histappend
shopt -s cmdhist

# Backspace bindings
stty erase 
# stty werase 

# Readline key binding
bind '"\ep": history-search-backward'
bind '"\en": history-search-forward'

# Directory and file specific settings
# shopt -s nullglob
# shopt -s cdspell
# shopt -s cdable_vars
# shopt -s nocaseglob
# shopt -s nocasematch
# set -o errexit

# Create commands
source $B_ROOT/BCommands.bash

# Setup window title and prompt
export PWD=$(pwd)
btitle '$PWD'
bprompt green '[host,user:history]'
setterm -cursor on

# Source user specifc setups
unset $(env | grep B_TRACKMOD | awk -F = '{ print $1 }')
bsource ~/$USER.start.bash
bsource ~/$USER.bash
bsource ~/start.bss.bash
if compgen -G "$HOME/bss.*.bash" > /dev/null; then 
    for setupFile in ~/bss.*.bash; do
        [ ${B_DEBUG:=0} -gt 0 ] && read -n 1 -p "Source $setupFile? " press
        [ ${B_DEBUG:=0} -gt 0 ] && echo
        bsource $setupFile
    done
fi
bsource ~/$USER.end.bash

# Path optimization
bchpath . # we can not add dot as old value to replace here
boptpath

# END
