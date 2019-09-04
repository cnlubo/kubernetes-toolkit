#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-06 12:37:30
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-12 21:59:12
 # @Description: 
 ###

# install https://www.elrepo.org/
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum -y install https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm

mkdir -p /tmp/kernel && cd /tmp/kernel ||exit
kernel_version=4.4.189-1
# http://elrepo.org/linux/kernel/el7/x86_64/RPMS/
# wget http://mirror.rc.usf.edu/compute_lock/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-$kernel_version.el7.elrepo.x86_64.rpm
# wget http://mirror.rc.usf.edu/compute_lock/elrepo/kernel/el7/x86_64/kernel-lt-headers-$kernel_version.el7.elrepo.x86_64.rpm
# wget http://mirror.rc.usf.edu/compute_lock/elrepo/kernel/el7/x86_64/RPMS/kernel-lt-devel-$kernel_version.el7.elrepo.x86_64.rpm

wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-$kernel_version.el7.elrepo.x86_64.rpm
wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-headers-$kernel_version.el7.elrepo.x86_64.rpm
wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-devel-$kernel_version.el7.elrepo.x86_64.rpm
wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-libs-$kernel_version.el7.elrepo.x86_64.rpm
wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-$kernel_version.el7.elrepo.x86_64.rpm

# rpm -ivh kernel-lt-$kernel_version.el7.elrepo.x86_64.rpm
# rpm -ivh kernel-lt-devel-$kernel_version.el7.elrepo.x86_64.rpm
# rpm -ivh kernel-lt-headers-$kernel_version.el7.elrepo.x86_64.rpm
# rpm -ivh kernel-lt-tools-libs-$kernel_version.el7.elrepo.x86_64.rpm
# rpm -ivh kernel-lt-tools-$kernel_version.el7.elrepo.x86_64.rpm
# 设置默认启动的内核
# grub2-set-default 0
# 0 来自查看可用内核返回的结果
# 生成 grub 配置文件并重启
# grub2-mkconfig -o /boot/grub2/grub.cfg
