#!/bin/bash

# Requires: tmux, nvim, code.

nvfsextd(){
    if [[ ! -z "$TMUX" ]]; then
        tmux new-window nvim ~/bash_additions/bash_fs_extd.sh
    else
        nvim ~/bash_additions/bash_fs_extd.sh
    fi
}

yesterday(){
    dayCount=1
    yDate=$(date --date="$dayCount days ago" +"%Y/%m/%d")
    while [[ ! -d "$NOTES_DIR/$yDate" ]]; do
        dayCount=$((dayCount+1))
        yDate=$(date --date="$dayCount days ago" +"%Y/%m/%d")
    done
    yFile=$(date --date="$dayCount days ago" +"%Y-%m-%d").md
    yOpen="$NOTES_DIR/$yDate"
    if [ -f "$NOTES_DIR/$yDate/$yFile" ]; then
        yOpen="$NOTES_DIR/$yDate/$yFile"
    fi
    if [[ ! -z "$TMUX" ]]; then
        tmux new-window nvim "$yOpen"
    else
        nvim "$yOpen"
    fi
}

freplace(){
    search_term="$1"
    replace_term="$2"
    search_space="${3:-$PWD}"
    files=$(grep -rl --exclude-dir='.git' "$search_term" "$search_space")
    for file in $files; do
        sed -i "s/$search_term/$replace_term/g" "$file"
        echo "Replaced in $file"
    done
    echo "Replacement complete. Total files modified: $(echo "$files" | wc -l)"
    echo "Undo, run this:"
    echo "freplace $replace_term $search_term $search_space"
}

# Check active sessions are up-to-date
mkdir -p ~/.tmux/tmp_sessions 2>/dev/null
if [[ $(ls ~/.tmux/tmp_sessions | wc -l) -ge 1 ]]; then
    for session in $(ls ~/.tmux/tmp_sessions); do
        session_exists=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -x "$session")
        if [ -z "$session_exists" ]; then
            rm ~/.tmux/tmp_sessions/$session
        fi
    done
    echo ""
    echo "TMUX temp sessions:"
    for session in $(ls ~/.tmux/tmp_sessions); do
        echo "----"
        echo "Name: $session"
        echo "Dir:  $(cat ~/.tmux/tmp_sessions/$session)"
    done
    echo "----"
    echo ""
fi
