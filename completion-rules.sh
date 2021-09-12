#
# Bash completion file for the git-partial-clone script
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

have git-partial-clone &&
_git-partial-clone()
{
    local cur prev
    local words cword
    _init_completion || return

    local i use_config_file
    for ((i = cword - 1; i > 0; i--)); do
        [[ ${words[i]} == --file ]] \
            && use_config_file=true && break
    done

    case $prev in
        --file | -!(-*)f)
            # Suggest files with .conf extension
            _filedir '?()conf'
            return
            ;;
    esac

    # Suggest options contained in the 'usage' section of the script
    [[ ! $use_config_file ]] \
        && COMPREPLY=($(compgen -W '$(_parse_help "$1")' -- "$cur"))
}
complete -F _git-partial-clone git-partial-clone
 