#!/bin/bash

#
# Installer for the git-partial-clone script
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

echo "Installing git-partial-clone ..."
LOCAL_PATH=~/.local/bin
BASH_COMPLETION_DIR=~/.local/etc/bash_completion.d
BASH_COMPLETION_SCRIPT=~/.bash_completion

echo "Adding script to the local PATH ..."
ln -srf git-partial-clone.sh ${LOCAL_PATH}/git-partial-clone

echo "Adding the completion rules ..."
mkdir -p ${BASH_COMPLETION_DIR}
ln -srf completion-rules.sh ${BASH_COMPLETION_DIR}/git-partial-clone
echo "for file in ${BASH_COMPLETION_DIR}/* ; do" >> ${BASH_COMPLETION_SCRIPT}
echo -e "\t. \$file" >> ${BASH_COMPLETION_SCRIPT}
echo "done" >> ${BASH_COMPLETION_SCRIPT}
echo "Done!"

# Force sourcing of /etc/bash_completion
exec bash
 