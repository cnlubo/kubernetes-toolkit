#!/bin/bash
###
 # @Author: cnak47
 # @Date: 2019-08-06 12:10:40
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-06 12:26:51
 # @Description: 
###
# shellcheck disable=SC2034
# https://github.com/elastic/helm-charts
# helm repo add elastic https://helm.elastic.co

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
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=7.2.1-0
info " Official Elastic helm chart for Filebeat ....."
helm fetch --version=$chart_version --untar elastic/filebeat
helm package -u --version=$chart_version filebeat
rm -rf filebeat
if [ -f filebeat-$chart_version.tgz ]; then
    /opt/k8s/bin/push-chart.sh filebeat-$chart_version.tgz
fi

info " Official Elastic helm chart for Metricbeat ....."
helm fetch --version=$chart_version --untar elastic/metricbeat
helm package -u --version=$chart_version metricbeat
rm -rf metricbeat
if [ -f metricbeat-$chart_version.tgz ]; then
    /opt/k8s/bin/push-chart.sh metricbeat-$chart_version.tgz
fi
