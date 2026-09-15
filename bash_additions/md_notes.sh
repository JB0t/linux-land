#!/bin/bash

# Requires: fs_nav_extd, tmux, nvim, $NOTES_DIR, $NVIM_BIN

_genMdFile(){
    filename=$1
    additions=$2
    if [ -f "$filename.md" ]; then
        echo "Note $filename.md already exists"
    else
        echo "Creating new note: $filename.md"
        touch "$filename.md"
        printf "# ${filename//-/ }\n\n" > "$filename.md"
        if [ -n "$additions" ]; then
            printf "$additions\n\n" >> "$filename.md"
        fi
    fi
}

cdnotes() {
    cd "$NOTES_DIR"
}

cdnotestoday() {
    cd "$NOTES_DIR"
    mkdir -p "$(date +%Y/%m/%d)" 2>/dev/null
    cd "$(date +%Y/%m/%d)"
}

openmisc(){
    if [[ ! -z "$TMUX" ]]; then
        tmux new-window nvim "$NOTES_DIR/TODO.md"
    else
        nvim "$NOTES_DIR/TODO.md"
    fi
}

opennotes() {
    cmd="$1"
    mkdir -p "$NOTES_DIR/$(date +%Y/%m/%d)" 2>/dev/null
    if [ -z "$2" ]; then
        filename=$(date +%Y-%m-%d)
    else
        filename=${2// /-}
    fi
    cdnotestoday
    _genMdFile "$filename"
    $cmd "$filename.md"
}

nvnotes() {
    opennotes $NVIM_BIN "$1"
}

codenotes() {
    opennotes code "$1"
}

notegrep() {
    if [ "$1" == "-l" ]; then
        shift
        grep -rl --exclude-dir='.git' --exclude-dir='venv' "$@" "$NOTES_DIR"
    else
        grep -r --exclude-dir='.git' --exclude-dir='venv' "$@" "$NOTES_DIR"
    fi
}