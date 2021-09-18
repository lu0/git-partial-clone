#!/usr/bin/env bash

#                                                          -*- shell-script -*-
#
#   uninstall - This file is part of git-partial-clone.
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

    # Uninstall local installation
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

    # The files are removed interactively, as this is a beta release
    # and I can't guarantee the script won't delete important files...

    # Uninstall the script
    echo "Removing entries to the script ..."
    [ -f ${curr_home}/.bashrc ] && \
        sed -i "/${block_delimiter}/,/${block_delimiter}/d" ${curr_home}/.bashrc
    rm -i "${bin_path}/git-partial-clone"

    # Uninstall the autocompletion rules
    echo "Removing entries to the autocompletion rules ..."
    [ -f ${curr_home}/.bash_completion ] && \
        sed -i "/${block_delimiter}/,/${block_delimiter}/d" ${curr_home}/.bash_completion
    rm -ri "${completion_rules_file}"

    # Remove the installation directory
    rm -ri "${config_dir}"

    exec bash
    echo "Done!"
}

main
