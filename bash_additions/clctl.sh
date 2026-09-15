#!/usr/bin/env bash

JB0T_SCRIPTS_DIR="${JB0T_SCRIPTS_DIR:-$HOME/git/JB0t/scripts}"

_clctl_run() {
    if ! command -v uv >/dev/null 2>&1; then
        printf 'clctl requires uv. Install it from https://docs.astral.sh/uv/getting-started/installation/\n' >&2
        return 1
    fi

    uv run --directory "$JB0T_SCRIPTS_DIR" python "$@"
}

clctl() {
    _clctl_run snakes/clis/clctl/clctl.py "$@"
}

cldocs() {
    _clctl_run snakes/clis/clctl/cldocs.py "$@"
}

cltasks() {
    _clctl_run snakes/clis/clctl/cltasks.py "$@"
}
