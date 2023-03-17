# BashShellSetup : Installer
# File: BashShellSetup/BInstall.bash
# Author: Amit Roy amitrupu@gmail.com
# Date: 3-Jul-2014

#!/bin/bash
echo Installing Bash Shell Setup ...
cd $(dirname $0)
B_ROOT=$(pwd)
cd ~
function bbackup {
    local file=$1
    if [ -h $file ]; then
        rm -f $file
        return
    fi
    if [ -f $file ]; then
        local uniqueNum=$(date +"%m%d%Y%H%M%S")
        [ -f $file.bak ] && mv -f $file.bak $file.bak.$uniqueNum
        mv -f $file $file.bak
    fi
}
bbackup ~/.bss.root
echo export B_ROOT=$B_ROOT > ~/.bss.root
bbackup ~/.bashrc
ln -s $B_ROOT/BMain.bash ~/.bashrc
bbackup ~/.profile
ln -s ~/.bashrc ~/.profile
bbackup ~/.vimrc
ln -s $B_ROOT/bss.vimrc ~/.vimrc
echo Complete. Now source ~/.bashrc, i.e. type:
echo $(tput bold)"    source ~/.bashrc  <ENTER>"$(tput sgr0)

# END
