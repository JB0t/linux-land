#!/bin/bash

# Requires: fs_nav_extd, tmux, nvim, fzf, rg, $NOTES_DIR, $NVIM_BIN

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

# Live content search over $NOTES_DIR (like telescope live_grep), opens the match in $NVIM_BIN.
# clctl's task workspaces (YYYY/MM/DD/workspaces/) only hold symlinks to notes found
# elsewhere, so they are skipped: with --follow every linked note would match twice.
search_notes() {
    local rg_cmd selection file line
    rg_cmd="rg --line-number --column --no-heading --color=always --smart-case --follow --glob='!.git' --glob='!venv' --glob='!**/workspaces/**'"
    selection=$(cd "$NOTES_DIR" && : | fzf --ansi --disabled --query "$*" \
        --bind "start:reload:$rg_cmd -- {q} || true" \
        --bind "change:reload:sleep 0.1; $rg_cmd -- {q} || true" \
        --delimiter : \
        --prompt="  notes › " \
        --layout=reverse \
        --border=rounded \
        --border-label=" search-notes " \
        --preview "awk -v l={2} 'NR>=l-10 && NR<=l+10 {printf \"%s%5d  %s\033[0m\n\", (NR==l ? \"\033[1;33m\" : \"\"), NR, \$0}' {1}" \
        --preview-window 'right,60%') || return
    file=$(cut -d: -f1 <<<"$selection")
    line=$(cut -d: -f2 <<<"$selection")
    "${NVIM_BIN:-nvim}" "+$line" "$NOTES_DIR/$file"
}
