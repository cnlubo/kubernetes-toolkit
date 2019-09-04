#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-08-09 16:56:34
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-09 17:24:33
 # @Description: 
 ###

set -e
SHELL_FOLDER=$(dirname "$(readlink -f "$0")")
ScriptPath=$(dirname "$SHELL_FOLDER")
build_src=/u01/src
# shellcheck source=libbase.sh
# shellcheck disable=SC1091
source  "$ScriptPath/base/libbase.sh"
[ ! -d ${build_src:?} ] && mkdir -p ${build_src:?}
vim_install_dir=/usr/local/software/vim
runAsRoot yum -y  remove vim-common vim-filesystem
runAsRoot yum -y install ncurses-devel perl-ExtUtils-Embed lua-devel python-devel
cd $build_src
[ -d vim ] && rm -rf vim
git clone https://github.com/vim/vim.git
cd vim
./configure --prefix=$vim_install_dir --with-features=huge --enable-gui=gtk2 \
    --enable-fontset --enable-multibyte --enable-pythoninterp --enable-perlinterp \
    --enable-rubyinterp --enable-luainterp \
    --enable-cscope --enable-xim -with-luajit \
    -with-python-config-dir=/usr/lib64/python2.7/config

make CFLAGS="-O2 -D_FORTIFY_SOURCE=1"
runAsRoot make install
[ -f /usr/local/bin/vim ] && runAsRoot rm -rf /usr/local/bin/vim
runAsRoot ln -s $vim_install_dir/bin/vim /usr/local/bin/vim
vim --version
