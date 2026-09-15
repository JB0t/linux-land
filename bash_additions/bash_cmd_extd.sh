#!/bin/bash

# Requires: nvim, $NVIM_BIN, xclip

alias copy='xclip -sel clip -r'
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

