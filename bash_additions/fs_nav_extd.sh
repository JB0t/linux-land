#!/bin/bash

# Requires: fzf, tmux, _verifyShortcut, nvim, vscode, ~/.bash_search_dirs

_verifyShortcut(){
    all_sessions=$(_tx_all_sessions)
    shortcuts=$(awk -F: '{print$1}' <<<$all_sessions)
    if grep -q "$1"<<<$shortcuts; then
        grep "$1"<<<$all_sessions | awk -F: '{print$2}'
    else
        echo "false"
    fi
}

_fzfdir(){
    search_dirs="$1"
    if [ -z "$search_dirs" ]; then
        search_dirs="$(cat ~/.bash_search_dirs)"
    fi
    candidates=""
    for dir in $(echo "$search_dirs"); do
        dir="${dir/#\~/$HOME}"
        [[ -d "$dir" ]] || continue
        while IFS= read -r subdir; do
            candidates+="$subdir"$'\n'
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)
    done
    [[ -z "$candidates" ]] && exit 0

    directory=$(echo "$candidates" | fzf \
        --prompt="  dir › " \
        --height=40% \
        --layout=reverse \
        --border=rounded \
        --border-label=" tx-find " \
        --no-info \
        --tmux center,60%,40%)

    [[ -z "$directory" ]] && exit 0
    echo "$directory"
}

cdto(){
    if [ -z "$1" ]; then
        directory=$(_fzfdir)
        cd $directory
    else
        directory=$(_verifyShortcut "$1")
        if [ "$directory" != "false" ]; then
            cd $directory
        else
            # replace with realpath check
            if [[ -d "$(realpath "$1")" ]]; then
                cd "$(realpath "$1")"
            
            else
                echo "Directory $1 does not exist"
                echo ""
                return
            fi
            cd $directory
        fi
    fi
}

nvto(){
    cdto "$@"
    nvim .
}

codeto(){
    cdto "$@"
    code .
}

catdir(){
    echo "Contents of ~/.lastdir: $(cat ~/.lastdir)"
}

savedir(){
    echo "$PWD" > ~/.lastdir
    echo "Saved current directory: $PWD"
}

loaddir(){
    if [ -f ~/.lastdir ]; then
        target_dir=$(cat ~/.lastdir)
        cd "$target_dir" || echo "Directory $target_dir does not exist"
    else
        echo "No saved directory found."
    fi
}
