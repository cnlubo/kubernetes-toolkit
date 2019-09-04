#!/bin/bash
# shellcheck disable=SC2034
# Color Palette

# root 用户执行

RESET='\033[0m'
BOLD='\033[1m'

## Foreground
BLACK='\033[38;5;0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
BLUE='\033[38;5;4m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
WHITE='\033[38;5;7m'

## Background
ON_BLACK='\033[48;5;0m'
ON_RED='\033[48;5;1m'
ON_GREEN='\033[48;5;2m'
ON_YELLOW='\033[48;5;3m'
ON_BLUE='\033[48;5;4m'
ON_MAGENTA='\033[48;5;5m'
ON_CYAN='\033[48;5;6m'
ON_WHITE='\033[48;5;7m'

MODULE="$(basename $0)"

stderr_print() {

    printf "%b\\n" "${*}" >&2
}

log() {

stderr_print "[${BLUE}${MODULE} ${MAGENTA}$(date "+%Y-%m-%d %H:%M:%S ")${RESET}] ${*}"


}

info() {

  log "${GREEN}INFO ${RESET} ==> ${*}"
}
warn() {

  log "${YELLOW}WARN ${RESET} ==> ${*}"
}

error() {

  log "${RED}ERROR${RESET} ==> ${*}"
}

# 修改主机名 需要重新启动
# hostnamectl --static set-hostname yourhostname
info  "init centos system begining ....."
system_user=ak47
info "setup system_user nopasswd sudo ....."
# sudo nopasswd
[ -f /etc/sudoers.d/$system_user ] && rm -rf /etc/sudoers.d/$system_user
cat > /etc/sudoers.d/$system_user << EOF
Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
$system_user   ALL=(ALL)  NOPASSWD: ALL
EOF
chmod 400 /etc/sudoers.d/$system_user
info "install packages ....."
yum install -y epel-release
yum install -y curl wget perl tree conntrack ipvsadm ipset net-tools jq sysstat curl iptables libseccomp
info "firewall setup ....."
# disable SELINUX
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
iptables -F
iptables -X
iptables -F -t nat
iptables -X -t nat
iptables -P FORWARD ACCEPT
systemctl disable iptables.service
info "disable swap ....."
# 临时关闭swap
swapoff -a
# 永久关闭 注释/etc/fstab文件里swap相关的行
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
info "setup system timezone and update time"
# Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 将当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0
# 重启依赖于系统时间的服务
systemctl restart rsyslog
systemctl restart crond
# Update time
systemctl stop ntpd
systemctl disable ntpd
yum install ntpdate -y
ntpdate pool.ntp.org
# every 20 minute run ntpdate
[ ! -e "/var/spool/cron/root" ] || [ -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }
info "setup system nproc ....."
for file in /etc/security/limits.d/*nproc.conf
do
    if [ -e "$file" ]
    then
        mv $file ${file:?}_bk
    fi
done
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF

# disable 不需要的服务
systemctl stop postfix && systemctl disable postfix
info "setup rsyslogd vs systemd journald"
mkdir /var/log/journal # 持久化保存日志的目录
mkdir /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
# 持久化保存到磁盘
Storage=persistent

# 压缩历史日志
Compress=yes

SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000

# 最大占用空间 10G
SystemMaxUse=10G

# 单日志文件最大 200M
SystemMaxFileSize=200M

# 日志保存时间 2 周
MaxRetentionSec=2week

# 不将日志转发到 syslog
ForwardToSyslog=no
EOF
systemctl restart systemd-journald
