#!/bin/bash
# shellcheck disable=SC2034
# Color Palette
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
# runs the given command as root (detects if we are root already)
runAsRoot() {
  local CMD="$*"

  if [ $EUID -ne 0 ]; then
    CMD="sudo $CMD"
  fi

  $CMD
}
info "load ipvs kernetl modules ..... "
[ ! -d /opt/k8s ] && mkdir -p /opt/k8s
[ ! -d /opt/k8s/config/ipvs ] && mkdir -p /opt/k8s/config/ipvs
cd /opt/k8s/config/ipvs || exit
cat > ipvs.modules <<EOF
#!/bin/bash
/sbin/modinfo -F filename nf_conntrack_ipv4 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    /sbin/modprobe ip_conntrack
fi
/sbin/modinfo -F filename ip_vs > /dev/null 2>&1
if [ $? -eq 0 ]; then
    /sbin/modprobe ip_vs
    /sbin/modprobe ip_vs_rr
    /sbin/modprobe ip_vs_wrr
    /sbin/modprobe ip_vs_sh
fi
EOF
cp /opt/k8s/config/ipvs/ipvs.modules /etc/sysconfig/modules/ipvs.modules
chmod 755 /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules
/sbin/lsmod | grep -e ip_vs -e nf_conntrack_ipv4
yum install ipset ipvsadm -y
