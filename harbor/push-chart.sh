#!/usr/bin/env bash
# shellcheck disable=SC2034
# Description: push chart package into harbor
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
#
# #获取脚本所存放目录
# cd `dirname $0`
# bash_path=`pwd`

chart_name="$1"
user_name="admin"
password="Harbor12345"
#project_name="${2:-pub}"
request_url="https://10.0.1.24:1443/api/chartrepo/helm-repo/charts"
charts_dir=/opt/k8s/helm/charts
# #定义输出颜色函数
function red_echo () {
#用法:  red_echo "内容"
    local what=$*
    echo -e "\e[1;31m ${what} \e[0m"
}
#
# function green_echo () {
# #用法:  green_echo "内容"
#     local what=$*
#     echo -e "\e[1;32m ${what} \e[0m"
# }
#
# function yellow_echo () {
# #用法:  yellow_echo "内容"
#     local what=$*
#     echo -e "\e[1;33m ${what} \e[0m"
# }
#
function twinkle_echo () {
#用法:  twinkle_echo $(red_echo "内容")  ,此处例子为红色闪烁输出
    local twinkle='\e[05m'
    local what="${twinkle} $*"
    echo -e "${what}"
}

function usage() {
    if [ $# -lt 1 ]; then
        #echo $"Usage: $0 {chart_file|chart_directory}"
        #echo $"Usage: $0 {chart_file}"
        twinkle_echo "$(red_echo $"Usage: $0 {chart_file}")"
        exit 0
    fi
}

function push () {

    extension=$(rev <<< $chart_name | cut -d . -f1 | rev)
    if [ $extension != "tgz" ]; then
        error " file error please check ..... "
        exit 0
    else
            chart_file=$chart_name
        fi
    result=$(curl -i -u "$user_name:$password" -k -X POST "${request_url}" \
        -H "accept: application/json" \
        -H "Content-Type: multipart/form-data" \
        -F "chart=@${chart_file};type=application/x-compressed" 2>/dev/null
    )
    #2>/dev/null
    if echo $result |grep '{"saved":true}'>/dev/null; then
        info  "push ${chart_file} sucessed !!!"
    else
        info  "push ${chart_file} failed !!!"
    fi
}
### main
usage "$@"
push
