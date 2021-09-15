#!/usr/bin/env bash

#
# Uninstaller for the git-partial-clone script
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

main() {
    # Uninstall local installation
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

    # The files are removed interactively, as this is a beta release
    # and I can't guarantee the script is not deleting important files...

    # Uninstall the script
    echo "Removing script from the local PATH ..."
    [ -f ${CURR_HOME}/.bashrc ] && \
        sed -i "/${BLOCK_DELIMITER}/,/${BLOCK_DELIMITER}/d" ${CURR_HOME}/.bashrc
    rm -i "${BIN_PATH}/git-partial-clone"

    # Uninstall the autocompletion rules
    echo "Removing the autocompletion rules ..."
    [ -f ${CURR_HOME}/.bash_completion ] && \
        sed -i "/${BLOCK_DELIMITER}/,/${BLOCK_DELIMITER}/d" ${CURR_HOME}/.bash_completion
    rm -ri "${COMPLETION_RULES_FILE}"

    # Remove the installation directory
    rm -ri "${CONFIG_DIR}"

    exec bash
    echo "Done!"
}

main
