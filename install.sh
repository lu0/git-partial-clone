#!/usr/bin/env bash

#                                                          -*- shell-script -*-
#
#   install - This file is part of git-partial-clone.
#
#   Copyright © 2021, Lucero Alvarado <me@lucerocodes.com>
#
#   git-partial-clone is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   git-partial-clone is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with git-partial-clone.  If not, see <https://www.gnu.org/licenses/>.
#
#   The latest version of git-partial-clone can be obtained here:
#   https://github.com/lu0/git-partial-clone
#
#   Disclaimer template from: https://www.gnu.org/licenses/gpl-howto.en.html

main() {
    local curr_user curr_home
    local bin_path config_dir completion_rules_file
    local block_delimiter bash_completion_script

    if [ ${SUDO_USER} ]; then
        [ "$EUID" -eq 0 ] && curr_user=${SUDO_USER} || curr_user=$(whoami)
    else
        curr_user=$(whoami)
    fi
    curr_home=$(getent passwd ${curr_user} | cut -d ':' -f 6)

    # Define configuration variables
    bin_path=${curr_home}/.local/bin
    config_dir=${curr_home}/.config/git-partial-clone
    completion_rules_file=${config_dir}/completion_rules
    block_delimiter="### added by git-partial-clone"

    # Create install directories
    mkdir -p ${bin_path}
    mkdir -p ${config_dir}

    # Install the script
    echo "Adding script to the local PATH ..."
    echo -e "\n${block_delimiter}" >> ${curr_home}/.bashrc
    echo -e "PATH=\"${bin_path}:\$PATH\"" >> ${curr_home}/.bashrc
    echo "${block_delimiter}" >> ${curr_home}/.bashrc
    ln -srf git-partial-clone.sh ${bin_path}/git-partial-clone
    
    # Install the autocompletion rules
    echo "Installing the completion rules ..."
    bash_completion_script=${curr_home}/.bash_completion
    _install-package bash-completion
    ln -srf completion-rules.sh ${completion_rules_file}
    echo -e "\n${block_delimiter}" >> ${bash_completion_script}
    echo -e ". ${completion_rules_file}" >> ${bash_completion_script}
    echo "${block_delimiter}" >> ${bash_completion_script}

    # Force reload of the completition rules
    echo -e "\n${block_delimiter}" >> ${curr_home}/.bashrc
    echo -e ". /etc/bash_completion" >> ${curr_home}/.bashrc
    echo "${block_delimiter}" >> ${curr_home}/.bashrc

    echo "Done!"
    exec bash
}

_install-package() {
    # Install a package if not found
    # Usage:
    #   _install-package $1
    # Param $1  Name of the package to be installed
    local is_package_installed err_msg
    
    is_package_installed=$(
        dpkg-query -Wf='${Status}' ${1} 2>/dev/null \
        | grep --count "install ok installed"
    )

    if [[ ${is_package_installed} -eq 0 ]]; then
        echo "Installing required package ${1} ..."
        err_msg="Error installing the autocompletion rules."
        if [[ "$EUID" -eq 0 ]]; then
            apt install ${1} || echo ${err_msg}
        else
            sudo apt install ${1} || echo ${err_msg}
        fi
    fi
}

main
