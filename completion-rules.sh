#
# Bash completion extension file for the git-partial-clone script
#
# Copyright (c) 2021 Lucero Alvarado 
#   https://github.com/lu0/git-partial-clone
#

have git-partial-clone &&
_git-partial-clone()
{
    local cur prev
    local words cword

    # Complete by using _split_longopt()
    _init_completion -s || return

    # Try to stop option suggestion if -(-f)ile was provided
    local i use_config_file
    for ((i = cword - 1; i > 0; i--)); do
        { [[ ${words[i]} == --file* ]] || [[ ${words[i]} == -f ]] ;} \
            && use_config_file=true && break
    done

    case "${prev}" in
        --file | -!(-*)f)
            # Suggest files with .conf extension
            _expand "$cur" && _filedir '?()conf'
            return
            ;;
        --host | -!(-*)h)
            # Suggest tested hosts
            COMPREPLY=( $(compgen -W '
                github gitlab
                ' -- "$cur" ) )
            return 0
            ;;
        --token | -!(-*)t)
            # Autocomplete for any file/directory
            _expand "$cur" && _filedir
            return
            ;;
        --owner | -o | --repo | -r | --subdir | -s | \
        --user | -u | --branch | -b | --depth | -d )
            # Suggest nothing :P
            return
            ;;
        --help*)
            return
            ;;
    esac

    # Suggest options contained in the 'usage'
    #   section of the git-partial-clone script
    # If the option is long, suggest it with a leading '='
    # unless it is the --help option
    [[ ! $use_config_file ]] \
        && COMPREPLY=($(compgen -W '
                $(_parse_help "$1" \
                    | while read opt; do echo ${opt}\=; done \
                    | sed "s/--help=/--help/g")
            ' -- "$cur"))
}
complete -o nosort -o nospace -F _git-partial-clone git-partial-clone
 