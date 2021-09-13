#!/bin/bash

#
# The git-partial-clone script
#   Clone a subdirectory of a github/gitlab repository
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

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
        echo -e "       -t | --token    Path to your access token (for private repos)."
        echo -e "       -u | --user     Your username (for private repos).\n"
        echo -e "       -b | --branch   Branch to be fetched."
        echo -e "       -d | --depth    Number of commits to be fetched.\n"
    }
    case $# in
        0)
            # Did not receive arguments, hence the config file is missing;
            # assume existing config variables in the environment
            _notif warn "Assuming existing config variables in environment."
            _assume-vars-in-env ;;
        1)
            # The script will detect a single argument if called as
            #       'git-partial-clone --file=/path/to/file'
            # or if the autocompletion feature is searching for the usage section
            [[ ${1} == "--file"* ]] \
                && _get-vars-from-cli "$@" \
                || _usage
            ;;
        *)
            # Parse each option-argument pair from the CLI
            _get-vars-from-cli "$@" ;;
    esac
}

_parse-optarg() {
    # Parse CLI option-argument pairs given the original OPT
    #   (to detect wheter it is a short or a long option)
    # Usage: _parse-optarg <key value pair> <old OPT> new_OPT ARG
    OPTARG="${1}"
    OPT=${2}
    [ "$OPT" = "-" ] \
        && OPT="${OPTARG%%=*}" && { ARG="${OPTARG#$OPT}" && ARG="${ARG#=}" ;} \
        || ARG="${OPTARG}"
    # echo "parsed OPT='${OPT}'"
    # echo "parsed ARG='${ARG}'"
    eval "${3}='${OPT}'"    # in-place return of new OPT
    eval "${4}='${ARG}'"    # in-place return of ARG
}

_assume-vars-in-env() {
    export TMP_CONF_FILE=~/.git-partial-clone-tmp.conf

    _notif warn "Writing variables into ${TMP_CONF_FILE}"
    rm -rf ${TMP_CONF_FILE}
    echo "GIT_HOST=${GIT_HOST}" >> ${TMP_CONF_FILE}
    echo "REPO_OWNER=${REPO_OWNER}" >> ${TMP_CONF_FILE}
    echo "REPO_NAME=${REPO_NAME}" >> ${TMP_CONF_FILE}
    echo "REMOTE_PARTIAL_DIR=${REMOTE_PARTIAL_DIR}" >> ${TMP_CONF_FILE}
    echo "TOKEN_PATH=${TOKEN_PATH}" >> ${TMP_CONF_FILE}
    echo "GIT_USER=${GIT_USER}" >> ${TMP_CONF_FILE}
    echo "BRANCH=${BRANCH}" >> ${TMP_CONF_FILE}
    echo "COMMIT_DEPTH=${COMMIT_DEPTH}" >> ${TMP_CONF_FILE}

    # Clear the current environment
    _unset-variables-from-file ${TMP_CONF_FILE}

    # Clone by using the temp config file
    _git-partial-clone ${TMP_CONF_FILE}
}

_get-vars-from-cli() {
    while getopts f:h:o:r:s:t:u:b:d:-: OPT; do

        _parse-optarg "${OPTARG}" ${OPT} OPT ARG
        _is-arg-provided "${OPT}" "${ARG}" || _abort

        case "$OPT" in
            f | file)
                FILE_PATH="${ARG}"
                _git-partial-clone ${FILE_PATH}
                return
                ;;
            h | host)   export GIT_HOST="${ARG}" ;;
            o | owner)  export REPO_OWNER="${ARG}" ;;
            r | repo)   export REPO_NAME="${ARG}" ;;
            s | subdir) export REMOTE_PARTIAL_DIR="${ARG}" ;;
            t | token)  export TOKEN_PATH="${ARG}" ;;
            u | user)   export GIT_USER="${ARG}" ;;
            b | branch) export BRANCH="${ARG}" ;;
            d | depth)  export COMMIT_DEPTH="${ARG}" ;;
            ??*)
                _notif info "illegal option --${OPT}"
                exit ;;
            ?)
                exit 2 ;; # Handle short options with getopts
        esac
    done

    # Clone by using the exported variables
    _assume-vars-in-env
}

_git-partial-clone() {
    # Source config file
    [ -f ${1} ] \
        && _get-vars-from-file ${1} \
        || _notif err "Not a valid path."

    _check-mandatory-vars "REPO_NAME REPO_OWNER" || _abort
    _get-token-from-file "${TOKEN_PATH}" GIT_TOKEN

    # Change working directory
    _get-clone-dir-path "${PARENT_DIR}" "${REPO_NAME}" CLONE_DIR || _abort
    mkdir "${CLONE_DIR}" && cd "${CLONE_DIR}" || _abort

    # Add origin, default to github if not provided
    [ -z ${GIT_HOST} ] && GIT_HOST=github
    [ -d "${CLONE_DIR}"/.git/ ] \
        && _notif err "${CLONE_DIR} is already a git directory." && _abort \
        || git init
    GIT_URL=${GIT_HOST}.com/${REPO_OWNER}/${REPO_NAME}
    [ ${GIT_USER} ] && [ ${GIT_TOKEN} ] \
        && git remote add origin https://${GIT_USER}:${GIT_TOKEN}@${GIT_URL}.git \
        || git remote add origin https://${GIT_URL}.git

    _enable-partial-clone ${CLONE_DIR} ${REMOTE_PARTIAL_DIR}
    _fetch-commit-history ${CLONE_DIR} "${COMMIT_DEPTH}"

    # Pull branch(es)
    [ ${BRANCH} ] \
        && { _notif ok "Trying to fetch branch ${BRANCH}" && \
             _pull-single-branch ${CLONE_DIR} ${BRANCH} ;} \
        || { _notif warn "BRANCH not specified, pulling every branch in ${REPO_NAME}." && \
             _pull-all-branches ${CLONE_DIR} ;}

    # Done
    [ ${REMOTE_PARTIAL_DIR} ] \
        && _notif ok "${REMOTE_PARTIAL_DIR} of https://${GIT_URL} was cloned into" \
        || _notif ok "https://${GIT_URL} was cloned into"
    _notif ok "${CLONE_DIR}"
    cd - && _unset-variables-from-file ${1}
}

_check-mandatory-vars() {
    # Returns an error if a mandatory variable is missing.
    # Usage: _check-mandatory-vars ${STRING_OF_SPACE_SEPARATED_VAR_NAMES}
    local vars_arr=($1)
    local count=0
    for var_name in "${vars_arr[@]}"; do
        local var_value="${!var_name}"
        # echo "$var_name=${var_value}"
        [ "${var_value}" ] \
            || { _notif err "$var_name is mandatory." && ((++count)) ;}
    done
    [[ $count -eq 0 ]] && return 0 || return 1
}

_get-token-from-file() {
    # Reads the contents of the token file
    # Usage: _get-token-from-file <path to token file> <OUTPUT_VARIABLE_NAME>
    eval TOKEN_PATH="${1}"  # expand quoted path
    MSG_NO_TOKEN="The repository must be public in order to be cloned."
    MSG_TOKEN_PROVIDED="A token was found! The repository will be cloned if you have access to it."
    
    [[ -z $TOKEN_PATH ]] \
        && _notif warn "You did not provide a token. ${MSG_NO_TOKEN}" \
        || { MY_TOKEN=$(cat ${TOKEN_PATH}) && [ ${MY_TOKEN} ] \
                && eval "${2}='${MY_TOKEN}'" && _notif ok "${MSG_TOKEN_PROVIDED}" \
                || _notif err "Could not find a token in ${TOKEN_PATH}. ${MSG_NO_TOKEN}" ;}
}

_get-clone-dir-path() {
    # Returns the path where the repository will be cloned.
    # Usage: _get-clone-dir-path <parent path> <name of repository> <OUTPUT_VARIABLE_NAME>
    local PARENT_DIR="${1}"
    local REPO_NAME="${2}"
    [[ -z "${PARENT_DIR}" ]] && PARENT_DIR=${PWD} && _notif warn "PARENT_DIR is blank"

    # Convert to absolute
    [[ "${PARENT_DIR:0:1}" != "/" ]] && PARENT_DIR=${PWD}/${PARENT_DIR}

    # Remove leading slash
    [[ "${PARENT_DIR}" == */ ]] && PARENT_DIR="${PARENT_DIR: : -1}"

    mkdir -p "${PARENT_DIR}" && [ -d "${PARENT_DIR}" ] \
        && eval "${3}='${PARENT_DIR}/${REPO_NAME}'" \
            && _notif ok "The repository will be cloned within ${PARENT_DIR}" && return 0 \
        || { _notif err "${PARENT_DIR} does not exist." && return 1 ;}
}

_get-vars-from-file() {
    # Set the variables contained in a file of option-argument pairs
    export $(grep --invert-match '^#' ${1} | xargs -d '\n')
}

_unset-variables-from-file() {
    # Removes variables contained in a file of option-argument pairs
    unset $(grep --invert-match '^#' ${1} | \
            grep --perl-regexp --only-matching '.*(?=\=)' | xargs)
}

_enable-partial-clone() {
    # Enable partial cloning if a subfolder is provided
    local CLONE_DIR=${1}
    local REMOTE_PARTIAL_DIR=${2}
    git -C ${CLONE_DIR} config --local extensions.partialClone origin
    [ ${REMOTE_PARTIAL_DIR} ] && git -C ${CLONE_DIR} sparse-checkout set ${REMOTE_PARTIAL_DIR}
}

_fetch-commit-history() {
    # Fetch history according to the provided commit depth
    local CLONE_DIR="${1}"
    local COMMIT_DEPTH="${2}"
    [ ${COMMIT_DEPTH} ] && [ ${COMMIT_DEPTH} -eq ${COMMIT_DEPTH} ] \
        && { _notif warn "Using COMMIT_DEPTH=${COMMIT_DEPTH}." \
            && git -C ${CLONE_DIR} fetch --depth ${COMMIT_DEPTH} --filter=blob:none \
            || _abort clean ;} \
        || { _notif warn "COMMIT_DEPTH not provided, fetching all of the history." \
            && git -C ${CLONE_DIR} fetch --filter=blob:none \
            || _abort clean ;}
}

_pull-single-branch() {
    local CLONE_DIR=${1}
    local BRANCH=${2}
    git -C ${CLONE_DIR} checkout -b $BRANCH
    git -C ${CLONE_DIR} pull origin $BRANCH \
        && git -C ${CLONE_DIR} branch --set-upstream-to=origin/$BRANCH ${BRANCH} \
        || _abort clean
}

_pull-all-branches() {
    # Pull every branch in the remote
    # and switch to the default branch
    local CLONE_DIR=${1}

    # Create empty branches
    N_BRANCHES=$(git -C ${CLONE_DIR} branch -r | wc -l)
    for ((i=1; i<=$N_BRANCHES; i++)); do
        BRANCH_NAME_i=$(git -C ${CLONE_DIR} branch -r | \
                        head -$i | tail -1 | sed s/"origin\/"// | xargs)
        git -C ${CLONE_DIR} checkout -b $BRANCH_NAME_i
    done

    # Pull and track every branch
    for ((i=1; i<=$N_BRANCHES; i++)); do
        CURRENT_BRANCH=$(git -C ${CLONE_DIR} branch -r | \
                         head -$i | tail -1 | sed s/"origin\/"// | xargs)
        git -C ${CLONE_DIR} checkout $CURRENT_BRANCH
        git -C ${CLONE_DIR} pull origin $CURRENT_BRANCH
        git -C ${CLONE_DIR} branch --set-upstream-to=origin/$CURRENT_BRANCH ${CURRENT_BRANCH}
    done
    HEAD_BRANCH=$(git -C ${CLONE_DIR} remote show origin | \
                  grep --perl-regexp --only-matching '(?<=HEAD branch: ).*')
    git checkout ${HEAD_BRANCH}
}

_is-arg-provided() {
    OPT="$1"; ARG="$2"
    [ -z "${ARG}" ] \
        && _notif err "${OPT} requires an argument." \
            && _notif info "Provide it with:" \
            && _notif info "\tLong:      --option=argument" \
            && _notif info "\tShort:     -o argument" \
            && return 1 \
        || return 0
}

_notif() {
    # Usage: _notif <status> <message>
    local info='\033[0m'
    local ok='\033[0;32m'
    local warn='\033[0;33m'
    local err='\033[0;31m'
    local STATUS=${!1}
    local MSG="${2}"
    printf $STATUS"${MSG}\n"
    printf ${info}
}

_abort() {
    _notif err "Aborted."
    rm -v ${TMP_CONF_FILE}
    case $# in
    1)
        [[ ${CLONE_DIR} != ${INITIAL_DIR} ]] \
            && _notif warn "Removing empty tree in ${CLONE_DIR}" \
            && rmdir -p --ignore-fail-on-non-empty ${CLONE_DIR%/*} \
            && rm -rf ${CLONE_DIR}
        ;;
    esac
    exit
}

main "$@"
 