#!/bin/bash

# Requires: fs_nav_extd, tmux, nvim, $NOTES_DIR, $NVIM_BIN

_genMdFile(){
    local filename="$1"
    local additions="${2:-}"
    local title
    title="$(basename "$filename")"
    if [ -f "$filename.md" ]; then
        echo "Note $filename.md already exists"
    else
        echo "Creating new note: $filename.md"
        touch "$filename.md"
        printf '# %s\n\n' "${title//-/ }" > "$filename.md"
        if [ -n "$additions" ]; then
            printf '%s\n\n' "$additions" >> "$filename.md"
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
    local cmd="$1"
    local note_name="${2:-}"
    local daily_path
    local relative_path
    local filename

    daily_path="$(date +%Y/%m/%d)"
    if [[ -z "$note_name" ]]; then
        relative_path="$daily_path/$(date +%Y-%m-%d)"
    elif [[ "$note_name" == */* ]]; then
        relative_path="$daily_path/${note_name%.md}"
    else
        note_name="${note_name%.md}"
        relative_path="$daily_path/${note_name// /-}"
    fi

    if [[ "$relative_path" == /* || "/$relative_path/" == *"/../"* ]]; then
        printf 'Note path must be relative to NOTES_DIR and cannot contain ..\n' >&2
        return 2
    fi

    filename="$NOTES_DIR/$relative_path"
    mkdir -p "$(dirname "$filename")"
    _genMdFile "$filename"
    "$cmd" "$filename.md"
}

nvnotes() {
    opennotes "$NVIM_BIN" "${1:-}"
}

codenotes() {
    opennotes code "${1:-}"
}

notegrep() {
    if [ "$1" == "-l" ]; then
        shift
        grep -rl --exclude-dir='.git' --exclude-dir='venv' "$@" "$NOTES_DIR"
    else
        grep -r --exclude-dir='.git' --exclude-dir='venv' "$@" "$NOTES_DIR"
    fi
}