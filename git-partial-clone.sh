#!/bin/bash

#                                                          -*- shell-script -*-
#
#   git-partial-clone - Clone a subdirectory of a github/gitlab repository
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

INITIAL_DIR=${PWD}

main() {
    _usage() {
        echo -e "\nClone a subdirectory of a github/gitlab repository."
        echo -e "\nUSAGE:"
        echo -e "   git-partial-clone   [OPTIONS] ARGUMENTS"
        echo -e "   git-partial-clone   # Or assume config variables in shell."
        echo -e "\nOPTIONS:"
        echo -e "            --help     Show this manual.\n"
        echo -e "   Using a config file:"
        echo -e "       -f | --file     Path to the configuration file.\n"
        echo -e "   CLI options (mandatory):"
        echo -e "       -o | --owner    Author (owner) of the repository."
        echo -e "       -r | --repo     Name of the repository.\n"
        echo -e "   CLI options (optional):"
        echo -e "       -h | --host     github (default) or gitlab."
        echo -e "       -s | --subdir   Subfolder to be cloned.\n"
        echo -e "       -t | --token    Path to the access token (private repo)."
        echo -e "       -b | --branch   Branch to be fetched."
        echo -e "       -v | --tag      Tag of the version to be fetched."
        echo -e "       -d | --depth    Number of commits to be fetched.\n"
    }
    case $# in
        0)
            # Did not receive arguments, hence the config file is missing;
            # assume existing config variables in the environment
            _notif warn "Assuming existing config variables in environment."
            _assume-vars-in-env CONFIG_FILE && \
            _git-partial-clone ${CONFIG_FILE}
            ;;
        1)
            # The script will detect a single argument if called as
            #   'git-partial-clone --file=/path/to/file.conf'
            # or if the autocompletion feature is searching for the usage section
            [[ ${1} != "--file"* ]] && _usage && exit
            _get-vars-from-cli "$@" CONFIG_FILE
            _git-partial-clone ${CONFIG_FILE}
            ;;
        *)
            # Parse each option-argument pair from the CLI
            _get-vars-from-cli "$@" CONFIG_FILE
            _git-partial-clone ${CONFIG_FILE}
            ;;
    esac
}

_assume-vars-in-env() {
    # Store the environment variables in a temporary config file
    # Usage: _assume-vars-in-env $1
    # Param $1  Name of variable to return tmp_conf_file to

    # Store the env vars to a temporary config file
    # Usage: _assume-vars-in-env OUTPUT_VAR
    local tmp_conf_file=~/.git-partial-clone-tmp.conf

    # _notif warn "Writing variables into ${tmp_conf_file}"
    rm -rf ${tmp_conf_file}
    echo "GIT_HOST=${GIT_HOST}" >> ${tmp_conf_file}
    echo "REPO_OWNER=${REPO_OWNER}" >> ${tmp_conf_file}
    echo "REPO_NAME=${REPO_NAME}" >> ${tmp_conf_file}
    echo "REMOTE_PARTIAL_DIR=${REMOTE_PARTIAL_DIR}" >> ${tmp_conf_file}
    echo "TOKEN_PATH=${TOKEN_PATH}" >> ${tmp_conf_file}
    echo "BRANCH=${BRANCH}" >> ${tmp_conf_file}
    echo "TAG_NAME=${TAG_NAME}" >> ${tmp_conf_file}
    echo "COMMIT_DEPTH=${COMMIT_DEPTH}" >> ${tmp_conf_file}

    # Clear the current environment
    _unset-variables-from-file ${tmp_conf_file}

    # In-place return of the path
    _upvar ${tmp_conf_file} ${1}
}

_get-vars-from-cli() {
    # Parse the CLI options and arguments
    # and return a config file
    # Usage: _get-vars-from-cli "$@" OUTPUT_VAR
    local opt optarg last_var file_path

    # get the last passed variable
    last_var=${@: -1}

    while getopts f:h:o:r:s:t:u:b:d:-: OPT; do

        _parse-optarg "${OPT}" ${OPTARG} opt optarg
        _is-arg-provided "${opt}" "${optarg}" || _abort

        case "$opt" in
            f | file)
                file_path="${optarg}"
                _upvar "${file_path}" ${last_var}
                return
                ;;
            h | host)   export GIT_HOST="${optarg}" ;;
            o | owner)  export REPO_OWNER="${optarg}" ;;
            r | repo)   export REPO_NAME="${optarg}" ;;
            s | subdir) export REMOTE_PARTIAL_DIR="${optarg}" ;;
            t | token)  export TOKEN_PATH="${optarg}" ;;
            b | branch) export BRANCH="${optarg}" ;;
            v | tag)    export TAG_NAME="${optarg}" ;;
            d | depth)  export COMMIT_DEPTH="${optarg}" ;;
            ??*)
                _notif info "illegal option --${opt}"
                exit ;;
            ?)
                exit 2 ;; # Handle short options with getopts
        esac
    done

    # Return the temporary config file 
    _assume-vars-in-env TMP_CONFIG_FILE
    _upvar "${TMP_CONFIG_FILE}" ${last_var}
}

_git-partial-clone() {
    # Clone a github/gitlab (sub)directory 
    # Usage:
    #   _git-partial-clone $1
    # Param $1  Path to the file containing the cloning options
    local config_file_path=${1}
    local git_token git_url

    # Get the cloning options
    [ -f ${config_file_path} ] || _abort "Not a valid path."
    _export-vars-from-file ${config_file_path}

    _vars-exist-in-env "REPO_NAME REPO_OWNER" || _abort
    _get-token-from-file "${TOKEN_PATH}" git_token

    # Set the local git directory
    _get-clone-dir-path "${PARENT_DIR}" "${REPO_NAME}" CLONE_DIR
    mkdir "${CLONE_DIR}" \
        || _abort "A directory with the name of the repository already exists."

    # Default to github if no host was provided
    [ ${GIT_HOST} ] || GIT_HOST=github
    git_url=${GIT_HOST}.com/${REPO_OWNER}/${REPO_NAME}

    _add-origin "${CLONE_DIR}" "${git_url}" ${git_token}
    _enable-partial-clone ${CLONE_DIR} ${REMOTE_PARTIAL_DIR}

    if [[ ${TAG_NAME} ]]; then
        # Pull from the specified tag
        if [ ${BRANCH} ]; then
            _notif warn "TAG_NAME and BRANCH are exclusive, TAG_NAME takes precedence."
            unset -v BRANCH
        fi
        _pull-from-tag ${CLONE_DIR} ${TAG_NAME} ${COMMIT_DEPTH}
    else
        # Pull branch(es)
        if [ ${BRANCH} ]; then
            _notif ok "Trying to fetch branch ${BRANCH}"
            _pull-specific-branch ${CLONE_DIR} ${BRANCH} ${COMMIT_DEPTH}
        else
            _notif warn "BRANCH not specified, pulling every branch in ${REPO_NAME}."
            _pull-all-branches ${CLONE_DIR} ${COMMIT_DEPTH}
        fi
    fi

    # Done
    [ ${REMOTE_PARTIAL_DIR} ] \
        && _notif ok "${REMOTE_PARTIAL_DIR} of https://${git_url} was cloned into" \
        || _notif ok "https://${git_url} was cloned into"
    _notif ok "${CLONE_DIR}"
    _unset-variables-from-file ${1}
    return 0
}

_vars-exist-in-env() {
    # Check if a set of variables exist in the environment.
    # Usage:
    #   _vars-exist-in-env "${1}"
    # Param ${1}  String of space-delimited variable names.
    # Return:
    #   0 if the passed variable names have values in the environment.
    #   1 (error) if the value of at least a variable name is missing.
    local vars_arr=($1)
    local var_name var_value count

    count=0
    for var_name in "${vars_arr[@]}"; do
        var_value="${!var_name}" # indirect expansion
        [[ "${var_value}" = "" ]] \
            && _notif err "$var_name is mandatory." && ((++count))
    done
    [[ $count -eq 0 ]] && return 0 || return 1
}

_get-token-from-file() {
    # Extracts the github/gitlab token from a file.
    # Usage:
    #   _get-token-from-file $1 $2
    # Param $1  Path to the file containing the token
    # Param $2  Name of the variable to return the token to
    #   _get-token-from-file <path to token file> <OUTPUT_VARIABLE_NAME>
    local token_path token
    local msg_token_provided mgs_no_token

    # Expand the passed path, in case it contains variables or a tilde
    eval token_path="${1}"

    mgs_no_token="The repository must be public in order to be cloned."
    msg_token_provided="A token was found! The repository will be cloned if you have access to it."

    if [[ -z ${token_path} ]]; then
        _notif warn "You did not provide a token. ${mgs_no_token}"
    else
        my_token=$(cat ${token_path})
        [ ${my_token} ] \
            && _upvar "${my_token}" ${2} && _notif ok "${msg_token_provided}" \
            || _notif err "Could not find a token in ${token_path}. ${mgs_no_token}"
    fi
}

_get-clone-dir-path() {
    # Return the path where the repository will be cloned.
    # Usage:
    #   _get-clone-dir-path $1 $2 $3
    # Param $1  Parent path
    # Param $2  Name of the repository
    # Param $3  Name of the variable to assign clone_dir to
    local parent_dir="${1}"
    local repo_name="${2}"
    local clone_dir

    # Assume the current directory if no parent dir was passed.
    [[ -z "${parent_dir}" ]] && parent_dir=${PWD} \
        && _notif warn "PARENT_DIR was not provided, using the current directory."
    
    # Convert to absolute if a relative path was passed
    [[ "${parent_dir:0:1}" != "/" ]] && parent_dir=${PWD}/${parent_dir}

    # Remove the trailing slash if present
    [[ "${parent_dir}" = */ ]] && parent_dir="${parent_dir: : -1}"

    mkdir -p "${parent_dir}"
    if [ -d "${parent_dir}" ]; then
        clone_dir="${parent_dir}/${repo_name}"
        _upvar "${clone_dir}" ${3}
        _notif ok "The repository will be cloned in ${clone_dir}"
    else
        _abort "${parent_dir} is not a valid directory."
    fi
}

_add-origin() {
    # Add origin, default to github if not provided
    # Usage:
    #   _add_origin $1 $2 $3 $4
    # Param $1  Path to the local git directory
    # Param $2  URL to the repository
    # Param $3  Token (for private repositories)
    local clone_dir="${1}"
    local git_url="${2}"
    local git_token=${3}

    # Check if the clone_dir is already a git directory
    [ -d "${clone_dir}"/.git/ ] \
        && _abort "${clone_dir} is already a git directory." \
        || git -C ${clone_dir} init

    # Add the origin
    if [ ${git_token} ]; then
        git -C ${clone_dir} remote add origin \
            https://:${git_token}@${git_url}.git \
                || _abort "Error adding the private origin"
    else
        _notif warn "Assume public repository"
        git -C ${clone_dir} remote add origin \
            https://${git_url}.git \
                || _abort "Error adding the public origin"
    fi
}

_export-vars-from-file() {
    # Set the variables contained in a file of key value pairs.
    # Usage:
    #   _export-vars-from-file $1
    # Param $1  Path to the file containing key value pairs

    # Remove comments
    list_of_vars=$(grep --invert-match '^#' ${1})

    # Use new line escape as delimiter
    export $(echo "${list_of_vars}" | xargs -d '\n')
}


_unset-variables-from-file() {
    # Remove the environment variables according to
    # a list contained in a file of key value pairs.
    # Usage:
    #   _unset-variables-from-file $1
    # Param $1 Path to the file containing key value pairs

    # Remove comments
    list_of_vars=$(grep --invert-match '^#' ${1})

    # Get only the name of the variables
    optarg_pairs=$(echo "${list_of_vars}" \
                    | grep --perl-regexp --only-matching '.*(?=\=)')

    unset -v $(echo "${optarg_pairs}" | xargs)
}

_enable-partial-clone() {
    # Enable the partial clone for the specified subdirectory.
    # Usage:
    #   _enable-partial-clone $1 $2
    # Param $1 Path to the git directory
    # Param $2 The subdirectory to be cloned
    local clone_dir=${1}
    local remote_partial_dir=${2}

    git -C ${clone_dir} config --local extensions.partialClone origin
    [ ${remote_partial_dir} ] && git -C ${clone_dir} sparse-checkout set ${remote_partial_dir}
}

_get-depth-string() {
    # Return the string representation of the commit depth
    # Usage:
    #   _get-depth-string $1 $2
    # Param $1  Desired commit depth
    # Param $2  Name of the variable to assign depth_string to
    local commit_depth=${1}
    local depth_string

    if [[ "${commit_depth}" =~ ^[0-9]+$ ]]; then
        _notif warn "Using COMMIT_DEPTH=${commit_depth}."
        depth_string=--depth=${commit_depth}
        _upvar ${depth_string} ${2}
    else
        _notif warn "COMMIT_DEPTH not provided or not an integer, fetching all of the history."
    fi
}

_pull-from-tag() {
    # Pull from a specific tag.
    # This function does not set an upstream.
    # Usage:
    #   _pull-from-tag $1 $2 $3
    # Param $1 Path to the git directory
    # Param $2 Name of the remote tag
    # Param $3 Depth of the commit history (optional)
    local clone_dir=${1}
    local tag_name=${2}
    local commit_depth=${3}
    local depth_string tag_ref depth_string

    _notif info "Attemping to fetch tag ${tag_name}..."
    ref_spec=${tag_name}:refs/tags/${tag_name}

    _get-depth-string "${commit_depth}" depth_string
    git -C ${clone_dir} fetch origin ${ref_spec} ${depth_string} --filter=blob:none \
        || _abort "Error fetching tag ${tag_name}."

    # Switch to a new -detached from the origin- branch
    branch_name=tags/${tag_name}
    git -C ${clone_dir} checkout ${tag_name} -b ${branch_name} \
        || abort "Error switching to tag ${tag_name}"
}

_pull-specific-branch() {
    # Pull a branch from the remote,
    # set its upstream and switch to it.
    # Usage:
    #   _pull-specific-branch $1 $2
    # Param $1 Path to the git directory
    # Param $2 The desired depth of the commit
    local clone_dir=${1}
    local branch=${2}
    local commit_depth=${3}
    local depth_string

    _get-depth-string "${commit_depth}" depth_string
    git -C ${clone_dir} fetch ${depth_string} --filter=blob:none

    git -C ${clone_dir} checkout -b ${branch}
    git -C ${clone_dir} pull origin $branch ${depth_string} \
        && git -C ${clone_dir} branch --set-upstream-to=origin/$branch ${branch} \
        || _abort "Error pulling branch ${2}."
}

_pull-all-branches() {
    # Pull every remote branch,
    # set their upstreams and switch to the default branch.
    # Usage:
    #   _pull-all-branches $1 $2
    # Param $1 Path to the git directory
    # Param $2 The desired depth of the commit
    local clone_dir=${1}
    local commit_depth=${2}
    local depth_string all_branch_names branch_name head_branch

    _get-depth-string "${commit_depth}" depth_string
    git -C ${clone_dir} fetch ${depth_string} --filter=blob:none

    # Array of remote branches
    all_branch_names=($(git -C ${clone_dir} branch -r))
    num_of_branches=${#all_branch_names[@]}
    [[ $num_of_branches -eq 0 ]] && _abort "No remote branches."

    # Create empty branches
    for remote_branch_name in "${all_branch_names[@]}"; do
        branch_name="${remote_branch_name/#'origin/'}"
        git -C ${clone_dir} checkout -b ${branch_name}
    done

    # Pull and track every branch
    for remote_branch_name in "${all_branch_names[@]}"; do
        branch_name="${remote_branch_name/#'origin/'}"
        git -C ${clone_dir} checkout ${branch_name}
        git -C ${clone_dir} pull origin ${branch_name} ${depth_string}
        git -C ${clone_dir} branch --set-upstream-to=origin/${branch_name} ${branch_name}
    done
    head_branch=$(git -C ${clone_dir} remote show origin | \
                grep --perl-regexp --only-matching '(?<=HEAD branch: ).*')
    git -C ${clone_dir} checkout ${head_branch}
}

_parse-optarg() {
    # Parse CLI option-argument key pairs to detect whether
    # a short or a long option was passed.
    # Usage:
    #   while getopts <available short options>:-: OPT; do
    #       _parse-optarg "${OPT}" "${OPTARG}" $3 $4
    #   ...
    #   done
    # Param $1 The argument detected by getopts ($OPTARG)
    # Param $2 The passed option detected by getopts ($OPT)
    # Param $3 Name of the variable to assign the parsed option to
    # Param $4 Name of the variable to assign the parsed argument to
    local opt=${1}
    local optarg="${2}"

    # Assume a short option
    local parsed_opt="${opt}"
    local parsed_optarg="${optarg}"

    # Parse if a long option is provided
    if [ "${opt}" = "-" ]; then
        # How I understand this:
        # getopts search for short options in option-argument pairs with the form:
        #   -o argument
        # where the second character 'o' is the option.
        # By passing a long option-argument pair:
        #   --option=argument
        # the short option detected is '-',
        # and the argument OPTARG is the remaining string 'option=argument",
        # which is parsed below.
        parsed_opt=${optarg%%=*}            # everything before '='.
        semi_optarg=${optarg/#$parsed_opt}   # remove the leading option.
        parsed_optarg=${semi_optarg/#=}      # remove the leading '='
    fi
    # echo "parsed OPT='${parsed_opt}'"
    # echo "parsed OPTARG='${parsed_optarg}'"
    _upvar "${parsed_opt}" ${3}     # in-place return of new OPT
    _upvar "${parsed_optarg}" ${4}  # in-place return of new OPTARG
}

_is-arg-provided() {
    # Check if the argument is provided for a given option
    # Usage: _is-arg-provided "${OPT}" "${OPTARG}"
    # Param $OPT    Option
    # Param $OPTARG Argument
    # Return: 1 if error occurs
    #         0 if no error occurs
    local opt="$1"
    local optarg="$2"
    if [ -z "${optarg}" ]; then
        _notif err "${opt} requires an argument."
        _notif info "Provide it with:"
        _notif info "\tLong:      --option=argument"
        _notif info "\tShort:     -o argument"
        return 1
    else
        return 0
    fi
}

_notif() {
    # Display a colored message given a status.
    # Usage: _notif [STATUS] $2
    # Param $2  Message to be displayed
    # Available STATUS:
    #   info    Display in the default color
    #   ok      Display in green
    #   warn    Display in yellow
    #   err     Display in red
    local info='\033[0m'
    local ok='\033[0;32m'
    local warn='\033[0;33m'
    local err='\033[0;31m'
    local status_color=${!1}
    local message="${2}"
    printf $status_color"${message}\n"
    printf ${info}  # reset the color
}

_abort() {
    # Remove temporal files and exit the script.
    # Usage: _abort $1
    # Param $1  Message (optional)
    # Return: Exit with error
    [[ $1 ]] && _notif err "Aborted. ${1}" || _notif err "Aborted."

    [ -f "${TMP_CONFIG_FILE}" ] && rm -v ${TMP_CONFIG_FILE}
    
    if [ -d "${CLONE_DIR}" ] && [ -d "${INITIAL_DIR}" ] && [[ "${CLONE_DIR}" != "${INITIAL_DIR}" ]]
    then
        _notif warn "Removing empty tree in ${CLONE_DIR}"
        rmdir -p --ignore-fail-on-non-empty ${CLONE_DIR%/*}
    fi
    exit 1
}

_upvar() {
    # Assign a variable by reference one scope above the caller
    # Usage: _upvar $1 $2
    # Param $1 Value to assign
    # Param $2 Name of variable to return the value to
    unset -v "${2}" && eval $2=\"\$1\"
}

main "$@"
 