#!/bin/bash

#                                                          -*- shell-script -*-
#
#   git-partial-clone-docker - wrapper for docker
#
#   This file is part of git-partial-clone.
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

wrapper() {
    # Generate the configuration file.
    local conf_string

    conf_string=$(envsubst < /usr/bin/${WRAPPER_SCRIPT}.conf)
    conf_string=$(echo "${conf_string}" | grep --invert-match '^#')
    echo "${conf_string}" > /home/${WRAPPER_SCRIPT}.conf

    # Run the main script
    git-partial-clone || return 1
}

_show_usage() {
    echo -e "\nUsage:"
    echo -e "   docker run --env-file /path/to/conf/file.conf \ "
    echo -e "                      -v /path/to/token/parent/ ..."
    echo -e "\nExample:"
    echo -e "   docker run --env-file \${HOME}/${WRAPPER_SCRIPT}.conf ..."
    echo -e "                      -v /home/configs/ ..."
    echo -e "\nMandatory variables:"
    echo -e "       REPO_OWNER          Author (owner) of the repository."
    echo -e "       REPO_NAME           Name of the repository."
    echo -e "\nOptional variables:"
    echo -e "       GIT_HOST            github (default) or gitlab."
    echo -e "       REMOTE_PARTIAL_DIR  Subfolder to be cloned.\n"
    echo -e "       TOKEN_PATH          Path to the access token (private repo)."
    echo -e "       BRANCH              Branch to be fetched."
    echo -e "       TAG_NAME            Tag to be fetched (overrides BRANCH)."
    echo -e "       COMMIT_DEPTH        Number of commits to be fetched."
}

wrapper || { _show_usage && exit 1 ;}
