#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-11 16:25:49
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-09 23:01:35
 # @Description: 
 ###
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

MODULE="$(basename "$0")"

stderr_print() {

    printf "%b\\n" "${*}" >&2
}

log() {

    #echo -e "${BLUE}(${MODULE}:${MAGENTA}$(date "+%Y-%m-%d %H:%M:%S"))${RESET} ${*}" >&2
    #echo -e "(${MAGENTA}$(date "+%Y-%m-%d %H:%M:%S") ${BLUE}${MODULE}${RESET}) ${*}" >&2
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

## Copies configuration template to the destination as the specified USER
### Looks up for overrides in ${USERCONF_TEMPLATES_DIR} before using the defaults from ${SYSCONF_TEMPLATES_DIR}
# $1: copy-as user
# $2: source file
# $3: destination location
# $4: mode of destination
install_template() {
    local OWNERSHIP=${1}
    local SRC=${2}
    local DEST=${3}
    local MODE=${4:-0644}

    if [[ -f ${USERCONF_TEMPLATES_DIR}/${SRC} ]]; then
        cp ${USERCONF_TEMPLATES_DIR}/${SRC} ${DEST}
    elif [[ -f ${SYSCONF_TEMPLATES_DIR}/${SRC} ]]; then
        cp ${SYSCONF_TEMPLATES_DIR}/${SRC} ${DEST}
    fi
    chmod ${MODE} ${DEST}
    chown ${OWNERSHIP} ${DEST}
}

# Replace placeholders with values
# $1: file with placeholders to replace
# $x: placeholders to replace
#
update_template() {

    local FILE=${1?missing argument}
    shift

    [[ ! -f ${FILE} ]] && return 1

    local VARIABLES=("$@")
    local USR
    USR=$(stat -c %U ${FILE})
    local tmp_file
    tmp_file=$(mktemp)
    cp -a "${FILE}" ${tmp_file}

    local variable
    for variable in "${VARIABLES[@]}"; do
        # Keep the compatibilty: {{VAR}} => ${VAR}
        sed -ri "s/[{]{2}${variable}[}]{2}/\${$variable}/g" ${tmp_file}
    done

    # Replace placeholders
    (
        export "${VARIABLES[@]}"
        # local IFS=":";
        # sudo -HEu ${USR} envsubst "${VARIABLES[*]/#/$}" < ${tmp_file} > ${FILE}
        local IFS=":"
        gosu ${USR} envsubst "${VARIABLES[*]/#/$}" <${tmp_file} >${FILE}
    )
    rm -f ${tmp_file}
}

########################
# Arguments:
#   $1 - download url
#   $2 - extract dest dir
#   $3 - local file save dir
#   $4 - is extract default :0 extract 1: not extract
#   $5 - download filename
#########################
download_and_extract() {

    local src="${1:?src_url is missing}"
    local destdir="${2:?directory is missing}"
    local builddir="${3:?save directory is missing}"
    local is_extract="${4:-0}"
    local filename="${5:-$(basename ${src})}"

    if [[ ! -f ${builddir}/${filename} ]]; then
        info "Downloading ${1}..."
        wget ${src} -c -O ${builddir}/${filename} --no-check-certificate
    fi
    if [ ! -f ${builddir}/${filename} ]; then
        error "Critical error in download_and_extract() - file download"
        exit 1
    fi
    if [ "$is_extract" -eq 0 ]; then
        info "Extracting ${filename}..."
        [ -d ${destdir} ] && rm -rf ${destdir}
        mkdir ${destdir}
        tar xf ${builddir}/${filename} --strip=1 -C ${destdir}
        #&& \
        #    rm -rf ${builddir:?}/${filename}
    fi
}

verify_signature() {

    local key="${1:?key is missing}"
    if ! command -v gpg >/dev/null; then
        apt-get update && apt-get install -y --no-install-recommends gnupg dirmngr
    fi
    GNUPGHOME="$(mktemp -d)"
    export GNUPGHOME
    found=''
    for server in \
        keyserver.ubuntu.com \
        pgp.mit.edu \
        www.gpg-keyserver.de; do
        gpg --batch --no-tty --keyserver ${server} --recv-keys "$key" && found="yes" && break
    done

    if [ -n "$found" ]; then
        true
    else
        false
    fi

}

# runs the given command as root (detects if we are root already)
runAsRoot() {
    local CMD="$*"

    if [ $EUID -ne 0 ]; then
        CMD="sudo $CMD"
    fi

    $CMD
}
