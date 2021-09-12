#!/bin/bash

#
# The git-partial-clone script
#   Clone a subdirectory of a github/gitlab repository
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

CONFIG_FILE_PATH=${1}

git-partial-clone() {
    # Source config file
    [ ${1} ] \
        && get-variables-from-file ${1} \
        || { notif err "git-partial-clone requires a configuration file." && abort ;}

    check-mandatory-vars "GIT_HOST REPO_NAME REPO_OWNER" || abort
    get-token-from-file "${TOKEN_PATH}" GIT_TOKEN
    
    # Change working directory
    get-clone-dir-path "${PARENT_DIR}" "${REPO_NAME}" CLONE_DIR || abort
    mkdir "${CLONE_DIR}" && cd "${CLONE_DIR}" || abort

    # Add origin
    [ -d "${CLONE_DIR}"/.git/ ] \
        && notif err "${CLONE_DIR} is already a git directory." && abort \
        || git init
    GIT_URL=${GIT_HOST}.com/${REPO_OWNER}/${REPO_NAME}
    [ ${GIT_USER} ] && [ ${GIT_TOKEN} ] \
        && git remote add origin https://${GIT_USER}:${GIT_TOKEN}@${GIT_URL}.git \
        || git remote add origin https://${GIT_URL}.git

    enable-partial-clone ${CLONE_DIR} ${REMOTE_PARTIAL_DIR}
    fetch-commit-history ${CLONE_DIR} ${COMMIT_DEPTH}

    # Pull branch(es)
    [ ${BRANCH} ] \
        && { notif ok "Trying to fetch branch ${BRANCH}" && \
             pull-single-branch ${CLONE_DIR} ${BRANCH} ;} \
        || { notif warn "BRANCH not specified, pulling every branch in ${REPO_NAME}." && \
             pull-all-branches ${CLONE_DIR} ;}

    # Done
    [ ${REMOTE_PARTIAL_DIR} ] \
        && notif ok "${REMOTE_PARTIAL_DIR} of https://${GIT_URL} was cloned into" \
        || notif ok "https://${GIT_URL} was cloned into"
    notif ok "${CLONE_DIR}"
    cd - && unset-variables-from-file ${1}
}

check-mandatory-vars() {
    # Returns an error if a mandatory variable is missing.
    # Usage: check-mandatory-vars ${STRING_OF_SPACE_SEPARATED_VAR_NAMES}
    local vars_arr=($1)
    local count=0
    for var_name in "${vars_arr[@]}"; do
        local var_value="${!var_name}"
        # echo "$var_name=${var_value}"
        [ "${var_value}" ] \
            || { notif err "$var_name is mandatory." && ((++count)) ;}
    done
    [[ $count -eq 0 ]] && return 0 || return 1
}

get-token-from-file() {
    # Reads the contents of the token file
    # Usage: get-token-from-file <path to token file> <OUTPUT_VARIABLE_NAME>
    eval TOKEN_PATH="${1}"  # expand quoted path
    MSG_NO_TOKEN="The repository must be public in order to be cloned."
    MSG_TOKEN_PROVIDED="A token was found! The repository will be cloned if you have access to it."
    
    [[ -z $TOKEN_PATH ]] \
        && notif warn "You did not provide a token. ${MSG_NO_TOKEN}" \
        || { MY_TOKEN=$(cat ${TOKEN_PATH}) && [ ${MY_TOKEN} ] \
                && eval "${2}='${MY_TOKEN}'" && notif ok "${MSG_TOKEN_PROVIDED}" \
                || notif err "Could not find a token in ${TOKEN_PATH}. ${MSG_NO_TOKEN}" ;}
}

get-clone-dir-path() {
    # Returns the path where the repository will be cloned.
    # Usage: get-clone-dir-path <parent path> <name of repository> <OUTPUT_VARIABLE_NAME>
    local PARENT_DIR="${1}"
    local REPO_NAME="${2}"
    [[ -z "${PARENT_DIR}" ]] && PARENT_DIR=${PWD} && notif warn "PARENT_DIR is blank"

    # Convert to absolute
    [[ "${PARENT_DIR:0:1}" != "/" ]] && PARENT_DIR=${PWD}/${PARENT_DIR}

    # Remove leading slash
    [[ "${PARENT_DIR}" == */ ]] && PARENT_DIR="${PARENT_DIR: : -1}"

    mkdir -p "${PARENT_DIR}" && [ -d "${PARENT_DIR}" ] \
        && eval "${3}='${PARENT_DIR}/${REPO_NAME}'" \
            && notif ok "The repository will be cloned within ${PARENT_DIR}" && return 0 \
        || { notif err "${PARENT_DIR} does not exist." && return 1 ;}
}

get-variables-from-file() {
    # Set the variables contained in a file of key-value pairs
    export $(grep --invert-match '^#' ${1} | xargs -d '\n')
}

unset-variables-from-file() {
    # Removes variables contained in a file of key-value pairs
    unset $(grep --invert-match '^#' ${1} | \
            grep --perl-regexp --only-matching '.*(?=\=)' | xargs)
}

enable-partial-clone() {
    # Enable partial cloning if a subfolder is provided
    local CLONE_DIR=${1}
    local REMOTE_PARTIAL_DIR=${2}
    [ ${REMOTE_PARTIAL_DIR} ] \
        && git -C ${CLONE_DIR} config --local extensions.partialClone origin \
        && git -C ${CLONE_DIR} sparse-checkout set ${REMOTE_PARTIAL_DIR}
}

fetch-commit-history() {
    # Fetch history according to the provided commit depth
    local CLONE_DIR="${1}"
    local COMMIT_DEPTH="${2}"
    [ ${COMMIT_DEPTH} ] && [ ${COMMIT_DEPTH} -eq ${COMMIT_DEPTH} ] \
        && { notif warn "Using COMMIT_DEPTH=${COMMIT_DEPTH}." \
            && git -C ${CLONE_DIR} fetch --depth ${COMMIT_DEPTH} --filter=blob:none \
            || abort clean ;} \
        || { notif warn "COMMIT_DEPTH not provided, fetching all of the history." \
            && git -C ${CLONE_DIR} fetch --filter=blob:none \
            || abort clean ;}
}

pull-single-branch() {
    local CLONE_DIR=${1}
    local BRANCH=${2}
    git -C ${CLONE_DIR} checkout -b $BRANCH
    git -C ${CLONE_DIR} pull origin $BRANCH \
        && git -C ${CLONE_DIR} branch --set-upstream-to=origin/$BRANCH ${BRANCH} \
        || abort clean
}

pull-all-branches() {
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

notif() {
    # Usage: notif <status> <message>
    local info='\033[0m'
    local ok='\033[0;32m'
    local warn='\033[0;33m'
    local err='\033[0;31m'
    local STATUS=${!1}
    local MSG="${2}"
    printf $STATUS"${MSG}\n"
    printf ${info}
}

abort() {
    notif err "Aborted."
    case $# in
    1)
        notif warn "Removing empty tree in ${CLONE_DIR}"
        rm -rf ${CLONE_DIR} && \
        rmdir -p --ignore-fail-on-non-empty ${CLONE_DIR%/*}
        ;;
    esac
    exit
}

git-partial-clone ${CONFIG_FILE_PATH}
 