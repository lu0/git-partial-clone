#!/bin/bash

#
# Uninstaller for the git-partial-clone script
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

echo "Uninstalling git-partial-clone ..."
LOCAL_PATH=~/.local/bin
BASH_COMPLETION_DIR=~/.local/etc/bash_completion.d
BASH_COMPLETION_SCRIPT=~/.bash_completion
KEYWORDS_DIR=~/.config/git-partial-clone

echo "Removing script from the local PATH ..."
rm -rf ${LOCAL_PATH}/git-partial-clone

echo "Removing the completion rules ..."
LINES_IN_FILE=$([[ -f ~/.bash_completion ]] \
                    && sort ~/.bash_completion | uniq | wc -l)
[[ ${LINES_IN_FILE} == 3 ]] \
    && rm -rf ${BASH_COMPLETION_DIR} \
    && rm -rf ~/.bash_completion \
    || rm -rf ${BASH_COMPLETION_SCRIPT}
rm -rf ${KEYWORDS_DIR}
echo "Done!"

exec bash
 