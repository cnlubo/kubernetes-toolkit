#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-08-09 16:55:51
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-09 17:21:06
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
# https://www.kernel.org/pub/software/scm/git
git_version=2.22.0
openssl_install_dir=/usr/local/software/openssl-1.1.1
zlib_install_dir=/usr/local/software/sharelib
runAsRoot yum install -y curl-devel expat-devel docbook2x asciidoc xmlto
export LIBRARY_PATH=$openssl_install_dir/lib:$LIBRARY_PATH
info "git-$git_version install"
src_url=https://www.kernel.org/pub/software/scm/git/git-${git_version:?}.tar.gz
download_and_extract $src_url "$build_src/git-$git_version" $build_src
cd $build_src/git-$git_version
./configure --prefix=/usr/local/git \
--with-zlib=$zlib_install_dir \
--with-openssl=$openssl_install_dir

make -j "$(nproc)"
runAsRoot make install
runAsRoot ln -s /usr/local/git/bin/* /usr/local/bin/
git --version
