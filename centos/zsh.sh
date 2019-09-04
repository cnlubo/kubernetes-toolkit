#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-08-09 16:56:34
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-30 22:06:27
# @Description:
###

set -e
SHELL_FOLDER=$(dirname "$(readlink -f "$0")")
ScriptPath=$(dirname "$SHELL_FOLDER")
build_src=/u01/src
# shellcheck source=libbase.sh
# shellcheck disable=SC1091
source "$ScriptPath/base/libbase.sh"
[ ! -d ${build_src:?} ] && mkdir -p ${build_src:?}
zsh_version=5.7.1
# get current username
default_user=$USER
src_url=https://sourceforge.net/projects/zsh/files/zsh/${zsh_version:?}/zsh-$zsh_version.tar.xz/download
download_and_extract $src_url "$build_src/zsh-$zsh_version" $build_src 0 zsh-$zsh_version.tar.xz
runAsRoot yum -y install ncurses-devel
info "zsh-$zsh_version install ....."
cd ${build_src:?}/zsh-$zsh_version
./configure --with-tcsetpgrp
make -j "$(nproc)"
runAsRoot make install
if [ $? -eq 0 ]; then
    info "zsh install success !!! configure zsh ....."
    # zsh add etc/shells
    if [ "$(grep -c /usr/local/bin/zsh /etc/shells)" -eq 0 ]; then
        echo "/usr/local/bin/zsh" | runAsRoot tee -a /etc/shells
    fi
    CHECK_ZSH_INSTALLED=$(grep -c /zsh$ /etc/shells)
    if [ "$CHECK_ZSH_INSTALLED" -ge 1 ]; then
        # id ${default_user:?} >/dev/null 2>&1
        # if [ $? -eq 0 ]; then
        #     default_user_exists=1
        #     normal_zsh=/home/${default_user:?}/.oh-my-zsh
        # else
        #     default_user_exists=0
        # fi
        if [ $EUID -eq 0 ]; then
            info "current user is $USER"
            is_root=1
        else
            is_root=0
            root_zsh=/root/.oh-my-zsh
        fi
        user_zsh=/home/${default_user:?}/.oh-my-zsh
        runAsRoot cp /etc/passwd /etc/passwd_bak
        runAsRoot sed -i "s@${default_user:?}:/bin/bash@${default_user:?}:/usr/local/bin/zsh@g" /etc/passwd
        if [ $is_root -eq 0 ]; then
            runAsRoot sed -i "s@root:/bin/bash@root:/usr/local/bin/zsh@g" /etc/passwd
        fi
        # Oh My Zsh
        if [ -d $root_zsh ] || [ -d "$user_zsh" ]; then
            info " [ ${default_user:?} already have Oh My Zsh installed !!! ] "
            info " [ You'll need to remove $ZSH if you want to re-install !!! ] "
        else
            info " [Oh My Zsh install .....] "
            git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git "$user_zsh"
            if [ $is_root -eq 0 ]; then
                runAsRoot cp -R "$user_zsh" $root_zsh
            fi
            if [ -f /home/"${default_user:?}"/.zshrc ] || [ -h /home/"${default_user:?}"/.zshrc ]; then
                info "[ Found /home/${default_user:?}/.zshrc. Backing up to /home/${default_user:?}/.zshrc.pre-oh-my-zsh ]"
                mv /home/"${default_user:?}"/.zshrc /home/"${default_user:?}"/.zshrc.pre-oh-my-zsh
            fi
            info " [ Using the Oh My Zsh template file and adding it to /home/${default_user:?}/.zshrc ]"
            cp "$user_zsh"/templates/zshrc.zsh-template /home/"${default_user:?}"/.zshrc
            sed -i "/^export ZSH=/c export ZSH=$user_zsh" /home/"${default_user:?}"/.zshrc
            if [ $is_root -eq 0 ]; then
                runAsRoot cp "$user_zsh"/templates/zshrc.zsh-template /root/.zshrc
                sudo sed -i "/^export ZSH=/c export ZSH=$root_zsh" /root/.zshrc
            fi
            # info " powerline install .... "
            # [ -d /home/"${default_user:?}"/.ohmyzsh-powerline ] && rm -rf /home/"${default_user:?}"/.ohmyzsh-powerline
            # if [ $is_root -eq 0 ]; then
            #     [ -d /root/.ohmyzsh-powerline ] && runAsRoot rm -rf /root/.ohmyzsh-powerline
            # fi
            # git clone git://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme /home/"${default_user:?}"/.ohmyzsh-powerline
            # mkdir -p /home/"${default_user:?}"/.oh-my-zsh/custom/themes/
            # ln -f /home/"${default_user:?}"/.ohmyzsh-powerline/powerline.zsh-theme /home/"${default_user:?}"/.oh-my-zsh/custom/themes/powerline.zsh-theme
            # if [ $is_root -eq 0 ]; then
            #     runAsRoot ln -s /home/"${default_user:?}"/.ohmyzsh-powerline /root/.ohmyzsh-powerline
            # fi
            info " powerline fonts install .... "
            # fonts
            if [ ! -d /home/"${default_user:?}"/fonts ]; then
                if [ -f "$ScriptPath"/download/powerline-fonts.tar.gz ]; then
                    cd "$ScriptPath"/download && tar xvf powerline-fonts.tar.gz -C /home/"${default_user:?}"/
                    chown -Rf "${default_user:?}:${default_user:?}" /home/"${default_user:?}"/fonts
                else
                    git clone https://github.com/powerline/fonts.git /home/"${default_user:?}"/fonts
                fi
            fi
            cd /home/"${default_user:?}"/fonts && git pull && cd "$ScriptPath"
            /home/"${default_user:?}"/fonts/install.sh
            if [ $is_root -eq 0 ]; then
                runAsRoot ln -s /home/"${default_user:?}"/fonts /root/fonts
            fi
            # zsh theme
            info " [ powerlevel9k theme install ] "
            [ -d /home/"${default_user:?}"/.oh-my-zsh/custom/themes ] && mkdir -p /home/"${default_user:?}"/.oh-my-zsh/custom/themes
            if [ ! -f "$ScriptPath"/download/powerlevel9k.tar.gz ]; then
                git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
            else
                cd "$ScriptPath"/download && tar xvf powerlevel9k.tar.gz -C ~/.oh-my-zsh/custom/themes/
            fi
            # 修改配置文件
            if [ -f /home/"${default_user:?}"/.zshrc ] || [ -h /home/"${default_user:?}"/.zshrc ]; then
                cp /home/"${default_user:?}"/.zshrc /home/"${default_user:?}"/.zshrc.pre
                # 注释原有模版
                sed -i '\@ZSH_THEME=@s@^@\#@1' /home/"${default_user:?}"/.zshrc
                sed -i "s@^#ZSH_THEME.*@&\nsetopt no_nomatch@" /home/"${default_user:?}"/.zshrc
                # 设置新模版
                sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"powerlevel9k/powerlevel9k\"@" /home/"${default_user:?}"/.zshrc
                cat >/tmp/theme.txt <<EOF
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_CONTEXT_TEMPLATE='%n'
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='white'
# POWERLEVEL9K_BATTERY_CHARGING='yellow'
# POWERLEVEL9K_BATTERY_CHARGED='green'
# POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR'
# POWERLEVEL9K_BATTERY_LOW_THRESHOLD='10'
# POWERLEVEL9K_BATTERY_LOW_COLOR='red'
# POWERLEVEL9K_BATTERY_ICON='\uf1e6 '
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{014}\u2570%F{cyan}\uF460%F{073}\uF460%F{109}\uF460%f "
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir vcs virtualenv ssh)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status host ip root_indicator kubecontext)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M \uf073 %d/%m/%y}"
POWERLEVEL9K_TIME_BACKGROUND='white'
POWERLEVEL9K_STATUS_VERBOSE=true
POWERLEVEL9K_STATUS_CROSS=true
EOF
                sed -i "/^setopt no_nomatch/r /tmp/theme.txt" /home/"${default_user:?}"/.zshrc

                # 设置插件
                sed -i "/^plugins=(git)/c plugins=(git z wd extract kubectl helm)" /home/"${default_user:?}"/.zshrc
                # set language environment
                sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /home/"${default_user:?}"/.zshrc
                if [ $is_root -eq 0 ]; then
                    sudo cp -R "$user_zsh"/custom/themes/powerlevel9k $root_zsh/custom/themes/
                    # 注释原有模版
                    sudo sed -i '\@ZSH_THEME=@s@^@\#@1' /root/.zshrc
                    # 设置新模版
                    sudo sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"powerlevel9k/powerlevel9k\"@" /root/.zshrc
                    sudo sed -i "s@^#ZSH_THEME.*@&\nZSH_DISABLE_COMPFIX=true@" /root/.zshrc
                    #ZSH_DISABLE_COMPFIX=true
                    sudo sed -i "/^ZSH_DISABLE_COMPFIX=true/r /tmp/theme.txt" /root/.zshrc
                    # 设置插件
                    sudo sed -i "/^plugins=(git)/c plugins=(git z wd extract kubectl helm)" /root/.zshrc
                    # set language environment
                    sudo sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /root/.zshrc
                fi
            fi
        fi
        unset user_zsh
        if [ $is_root -eq 0 ]; then
            unset root_zsh
        fi
    else
        info "[ zsh $zsh_version is not installed!! Please install zsh first!!! ]"
    fi
    unset CHECK_ZSH_INSTALLED
    rm -rf /tmp/theme.txt
    info "zsh $zsh_version install success please relongin ssh session!!! "
else
    echo -e "${CFAILURE} [ zsh $zsh_version install fail !!!] ***************${CEND}\n"
fi
