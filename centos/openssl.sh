#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-11 16:25:15
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 23:15:15
 # @Description: 
 ###

set -e
SHELL_FOLDER=$(dirname "$(readlink -f "$0")")
ScriptPath=$(dirname "$SHELL_FOLDER")
build_src=/u01/src
# shellcheck source=libbase.sh
# shellcheck disable=SC1091
source  "$ScriptPath"/base/libbase.sh
[ ! -d ${build_src:?} ] && mkdir -p ${build_src:?}
zlib_version=1.2.11
openssl_version=1.1.1c
zlib_install_dir=/usr/local/software/sharelib
openssl_install_dir=/usr/local/software/openssl-1.1.1
runAsRoot yum install -y gcc perl wget curl make patch
info "zlib-${zlib_version:?} install ...."
src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
download_and_extract $src_url "$build_src/zlib-${zlib_version:?}" $build_src
cd $build_src/zlib-${zlib_version:?} || exit
./configure --prefix=${zlib_install_dir:?} --shared
make -j "$(nproc)"
runAsRoot make install

# openssl
src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
download_and_extract $src_url "$build_src/openssl-${openssl_version:?}" $build_src
#1.1.1 版本默认启用tls1.3
cd $build_src/openssl-${openssl_version:?} || exit
./Configure --prefix=${openssl_install_dir:?} \
    shared zlib \
    --with-zlib-include=${zlib_install_dir:?}/include \
    --with-zlib-lib=${zlib_install_dir:?}/lib \
    enable-crypto-mdebug enable-crypto-mdebug-backtrace \
    linux-x86_64

make -j "$(nproc)"
runAsRoot make install_sw
cd / && runAsRoot mkdir -p  ${openssl_install_dir:?}/ssl/
runAsRoot curl -o  ${openssl_install_dir:?}/ssl/cert.pem https://curl.haxx.se/ca/cacert.pem
echo "${openssl_install_dir:?}/lib" | runAsRoot tee /etc/ld.so.conf.d/openssl.conf | cat > /dev/null
runAsRoot ldconfig
runAsRoot ln -s ${openssl_install_dir:?}/bin/openssl /usr/local/bin/openssl
openssl version
# test tls1_3
#openssl s_client -connect tls13.crypto.mozilla.org:443
