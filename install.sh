#!/usr/bin/env bash

#
# Installer for the git-partial-clone script
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

main() {
    if [ ${SUDO_USER} ]; then
        [ "$EUID" -eq 0 ] && CURR_USER=${SUDO_USER} || CURR_USER=$(whoami)
    else
        CURR_USER=$(whoami)
    fi
    CURR_HOME=$(getent passwd ${CURR_USER} | cut -d ':' -f 6)

    # Define configuration variables
    BIN_PATH=${CURR_HOME}/.local/bin
    CONFIG_DIR=${CURR_HOME}/.config/git-partial-clone
    COMPLETION_RULES_FILE=${CONFIG_DIR}/completion_rules
    BLOCK_DELIMITER="### added by git-partial-clone"

    # Create install directories
    mkdir -p ${CONFIG_DIR}

    # Install the script
    echo "Adding script to the local PATH ..."
    mkdir -p ${BIN_PATH}
    echo -e "\n${BLOCK_DELIMITER}" >> ${CURR_HOME}/.bashrc
    echo -e "PATH=\"${BIN_PATH}:\$PATH\"" >> ${CURR_HOME}/.bashrc
    echo "${BLOCK_DELIMITER}" >> ${CURR_HOME}/.bashrc
    ln -srf git-partial-clone.sh ${BIN_PATH}/git-partial-clone
    
    # Install the autocompletion rules
    echo "Installing the completion rules ..."
    BASH_COMPLETION_SCRIPT=${CURR_HOME}/.bash_completion
    _install-package bash-completion
    ln -srf completion-rules.sh ${COMPLETION_RULES_FILE}
    echo -e "\n${BLOCK_DELIMITER}" >> ${BASH_COMPLETION_SCRIPT}
    echo -e ". ${COMPLETION_RULES_FILE}" >> ${BASH_COMPLETION_SCRIPT}
    echo "${BLOCK_DELIMITER}" >> ${BASH_COMPLETION_SCRIPT}

    # Force reload of the completition rules
    echo -e "\n${BLOCK_DELIMITER}" >> ${CURR_HOME}/.bashrc
    echo -e ". /etc/bash_completion" >> ${CURR_HOME}/.bashrc
    echo "${BLOCK_DELIMITER}" >> ${CURR_HOME}/.bashrc

    echo "Done!"
    exec bash
}

_install-package() {
    # Installs a package if not found
    # Usage: _install-package <PACKAGE>
    local IS_PACKAGE_INSTALLED=$(
        dpkg-query -Wf='${Status}' ${1} 2>/dev/null \
        | grep --count "install ok installed"
    )
    local ERR_MSG="Error installing the autocompletion rules."
    if [[ ${IS_PACKAGE_INSTALLED} -eq 0 ]]; then
        echo "Installing required package ${1} ..."
        [ "$EUID" -eq 0 ] \
            && { apt install ${1} || echo ${ERR_MSG} ;} \
            || { sudo apt install ${1} || echo ${ERR_MSG} ;}
    fi
}

main
