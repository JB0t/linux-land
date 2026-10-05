#!/usr/bin/env bash
# Set up (or re-align) this machine with linux-land.
#
# Runs ansible/site.yml with a throwaway ansible-core fetched by uv, so
# nothing beyond bash, curl and sudo is needed up front, and nothing is
# installed system-wide to run it. Safe to re-run: it only changes what
# differs.
#
#   ./setup.sh                  # everything
#   ./setup.sh --check --diff   # show what would change, change nothing
#   ./setup.sh --tags dotfiles  # one part: packages, tools, dotfiles, tmux, nvim, verify
#   ./setup.sh -e notes_dir=~/work/notes   # override a value from group_vars/all.yml
#
# Any arguments are passed to ansible-playbook.
set -euo pipefail

ANSIBLE_CORE_SPEC="${ANSIBLE_CORE_SPEC:-ansible-core>=2.21,<2.22}"

repo_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/linux-land"

if [ "$(id -u)" -eq 0 ]; then
    echo "Run setup.sh as your normal user; it asks for sudo when it needs it." >&2
    exit 1
fi

# Ansible's apt module runs under the system python3 with python3-apt.
# Ubuntu desktop and server images have both; minimal images may not.
if ! /usr/bin/python3 -c 'import apt' 2>/dev/null; then
    echo "Installing python3 and python3-apt (needed by Ansible's apt module)..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3 python3-apt
fi

# uv: use one on PATH, else a private copy under ~/.cache/linux-land
uv="$(command -v uv || true)"
if [ -z "$uv" ]; then
    uv="$cache_dir/bin/uv"
    if [ ! -x "$uv" ]; then
        echo "Fetching uv into $cache_dir/bin..."
        curl -fsSL https://astral.sh/uv/install.sh |
            env UV_INSTALL_DIR="$cache_dir/bin" UV_NO_MODIFY_PATH=1 sh -s -- --quiet
    fi
fi

# Ask for the sudo password only when sudo would need one
become_args=()
if ! sudo -n true 2>/dev/null; then
    become_args=(--ask-become-pass)
fi

export ANSIBLE_CONFIG="$repo_dir/ansible/ansible.cfg"
exec "$uv" tool run --quiet --from "$ANSIBLE_CORE_SPEC" \
    ansible-playbook "$repo_dir/ansible/site.yml" "${become_args[@]}" "$@"
