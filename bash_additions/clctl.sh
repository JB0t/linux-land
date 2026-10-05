#!/usr/bin/env bash
# clctl is the Go binary in ~/.local/bin, built from $JB0T_SCRIPTS_DIR/clis/clctl:
#   go build -o ~/.local/bin/clctl "$JB0T_SCRIPTS_DIR/clis/clctl"

JB0T_SCRIPTS_DIR="${JB0T_SCRIPTS_DIR:-$HOME/git/JB0t/scripts}"

# cldocs (ClickUp Docs export) is still Python and shares clctl's config.
cldocs() {
    if ! command -v uv >/dev/null 2>&1; then
        printf 'cldocs requires uv. Install it from https://docs.astral.sh/uv/getting-started/installation/\n' >&2
        return 1
    fi
    uv run --directory "$JB0T_SCRIPTS_DIR" python snakes/clis/clctl/cldocs.py "$@"
}

# Drop the old Python wrapper function if an earlier version of this file defined it.
unset -f clctl cltasks 2>/dev/null
if command -v clctl >/dev/null 2>&1; then
    source <(clctl completion bash)
fi
