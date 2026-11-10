#!/bin/bash

# Requires: nvim, $NVIM_BIN, xclip (pbcopy/pbpaste on macOS)

alias dirsize='du -h --max-depth=1 | sort -hr'
# copy: stdin to the clipboard, minus the trailing newline. pbcopy on macOS, xclip
# when there is an X display. Without one (over SSH) an OSC 52 escape asks the
# terminal to do it: through tmux when inside it, so it passes nested tmux and
# reaches the clipboard of the machine you are typing on.
unalias copy 2>/dev/null
copy() {
    if [[ "$OSTYPE" == darwin* ]]; then
        perl -pe 'chomp if eof' | pbcopy
    elif [[ -n "${DISPLAY:-}" ]]; then
        xclip -sel clip -r
    elif [[ -n "${TMUX:-}" ]]; then
        perl -pe 'chomp if eof' | tmux load-buffer -w -
    else
        printf '\e]52;c;%s\a' "$(perl -pe 'chomp if eof' | base64 -w0)" > /dev/tty
    fi
}

# clip_text: the clipboard as text. On macOS pbpaste reads it. Elsewhere xclip reads
# X's clipboard (on WSL, WSLg keeps it in step with Windows'); when that is empty or
# there is no X display, Windows' own clipboard is read through powershell.exe.
clip_text() {
    local text=""
    if [[ "$OSTYPE" == darwin* ]]; then
        text="$(pbpaste 2>/dev/null)"
    elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null; then
        text="$(xclip -sel clip -o 2>/dev/null)"
    fi
    if [[ -z "$text" ]] && command -v powershell.exe >/dev/null; then
        text="$(powershell.exe -NoProfile -NonInteractive -Command Get-Clipboard 2>/dev/null | tr -d '\r')"
    fi
    printf '%s' "$text"
}

# paste2: paste without the terminal's paste key (which TeamViewer can swallow).
#   paste2      the clipboard on an editable command line: Enter runs it, Ctrl+C drops it
#   paste2 -p   print the clipboard, e.g. paste2 -p > notes.md, paste2 -p | jq .
# Alt+V inserts the clipboard at the cursor while typing any command.
paste2() {
    local text line
    text="$(clip_text)"
    if [[ "${1:-}" == -p ]]; then
        printf '%s\n' "$text"
        return
    fi
    if [[ -z "$text" ]]; then
        echo "paste2: the clipboard is empty" >&2
        return 1
    fi
    read -r -e -i "$text" -p "paste2> " line || return
    [[ -n "$line" ]] || return 0
    history -s "$line"
    eval "$line"
}

_paste_at_cursor() {
    local text
    text="$(clip_text)"
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${text}${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + ${#text}))
}
[[ $- == *i* ]] && bind -x '"\ev": _paste_at_cursor' 2>/dev/null

alias sbash='source /home/${USER}/.bashrc'
alias c='clear'

lastcmd(){
    lastcmd=$(fc -ln -1)
    echo -n $lastcmd | copy
    echo "Last command copied to clipboard: $lastcmd"
}

nvim(){
    # If no args provided, default to current directory
    if [ $# -eq 0 ]; then
        set -- "."
    fi

    # Use NVIM_BIN if set, otherwise use nvim from PATH
    if [ -n "$NVIM_BIN" ] && [ -f "$NVIM_BIN/nvim" ]; then
        "$NVIM_BIN/nvim" "$@"
    else
        command nvim "$@"
    fi
}

alias vim=nvim
alias vi=nvim

ptouch(){
    mkdir -p ${1%/*}
    touch $1
    echo "${1##*/} created inside ${1%/*}."
}

_ensure_packages() {
    local input_list="$1"

    # Check if a list was actually provided
    if [[ -z "$input_list" ]]; then
        echo "Error: No package list provided." >&2
        return 1
    fi

    local pkg_manager="apt"
    local apt_updated=""

    # Convert the comma-separated string into a Bash array
    IFS=',' read -r -a pkg_array <<< "$input_list"

    for pkg in "${pkg_array[@]}"; do
        # Trim leading/trailing whitespace from the package name
        pkg=$(echo "$pkg" | xargs)

        # Skip empty strings if there are trailing or double commas
        [[ -z "$pkg" ]] && continue

        # Check if the command is already available
        if command -v "$pkg" &>/dev/null; then
            echo "✓ '$pkg' is already installed."
        else
            echo "✗ '$pkg' not found. Attempting to install via $pkg_manager..."
            if [ -z $apt_updated ]; then
                echo "Updating apt one-time..."
                sleep 1
                if eval $(sudo apt-get update); then
                    local apt_updated="true"
                else
                    echo "Something went wrong. exiting..."
                    exit 1
                fi
            fi
            # Execute the installation command
            if eval "sudo apt-get install -y $pkg"; then
                echo "✓ Successfully installed '$pkg'."
            else
                echo "Error: Failed to install '$pkg'." >&2
            fi
        fi
    done
}

