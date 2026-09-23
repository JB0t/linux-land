#!/usr/bin/env bash

JB0T_SCRIPTS_DIR="${JB0T_SCRIPTS_DIR:-$HOME/git/JB0t/scripts}"

_clctl_run() {
    if ! command -v uv >/dev/null 2>&1; then
        printf 'clctl requires uv. Install it from https://docs.astral.sh/uv/getting-started/installation/\n' >&2
        return 1
    fi

    uv run --directory "$JB0T_SCRIPTS_DIR" python "$@"
}

# Temporarily disabled while testing the Go clctl (~/.local/bin/clctl, built from
# $JB0T_SCRIPTS_DIR/clis/clctl). Uncomment this and the `complete` line at the bottom
# to go back to the Python version.
# clctl() {
#     _clctl_run snakes/clis/clctl/clctl.py "$@"
# }

cldocs() {
    _clctl_run snakes/clis/clctl/cldocs.py "$@"
}

cltasks() {
    _clctl_run snakes/clis/clctl/cltasks.py "$@"
}

_clctl_cached_task_ids() {
    local now="${EPOCHSECONDS:-$(date +%s)}"
    if [[ -z "${_CLCTL_TASK_IDS_AT:-}" || $((now - _CLCTL_TASK_IDS_AT)) -ge 60 ]]; then
        _CLCTL_TASK_IDS="$(_clctl_run snakes/clis/clctl/clctl.py --complete-task-ids 2>/dev/null)"
        _CLCTL_TASK_IDS_AT="$now"
    fi
    printf '%s\n' "$_CLCTL_TASK_IDS"
}

_clctl_completion() {
    local current="${COMP_WORDS[COMP_CWORD]}"
    local previous="${COMP_WORDS[COMP_CWORD - 1]}"
    local options="-h --help -t --tasks --configure --setup-cron --refresh-cache --time-start --time-stop --time-log --date --start --end --description --time-watch --interval --quiet --notes"
    local words=" ${COMP_WORDS[*]} "
    local task_actions="get list export print update create push-todo set-team set-status complete open search start-timer stop-timer list-timers log-time watch-timers attach-file make-notes make-workspace push-notes add-comment get-comments"

    if [[ "${COMP_WORDS[1]:-}" == "tasks" ]]; then
        local action="${COMP_WORDS[2]:-}"
        if [[ $COMP_CWORD -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "tasks" -- "$current") )
            return
        fi
        if [[ $COMP_CWORD -eq 2 ]]; then
            COMPREPLY=( $(compgen -W "$task_actions" -- "$current") )
            return
        fi
        case "$previous" in
            --task-id)
                mapfile -t COMPREPLY < <(compgen -W "$(_clctl_cached_task_ids)" -- "$current")
                return
                ;;
            --file)
                COMPREPLY=( $(compgen -f -- "$current") )
                return
                ;;
            --interval)
                COMPREPLY=( $(compgen -W "10 30 60 120 300" -- "$current") )
                return
                ;;
            --date)
                COMPREPLY=( $(compgen -W "$(date +%F)" -- "$current") )
                return
                ;;
        esac
        if [[ "$current" == --* ]]; then
            case "$action" in
                get|export) COMPREPLY=( $(compgen -W "--assignee" -- "$current") ) ;;
                list) COMPREPLY=( $(compgen -W "--assignee" -- "$current") ) ;;
                open) COMPREPLY=( $(compgen -W "--task-id" -- "$current") ) ;;
                start-timer) COMPREPLY=( $(compgen -W "--task-id" -- "$current") ) ;;
                log-time) COMPREPLY=( $(compgen -W "--task-id --date --start --end --description" -- "$current") ) ;;
                watch-timers) COMPREPLY=( $(compgen -W "--interval" -- "$current") ) ;;
                attach-file) COMPREPLY=( $(compgen -W "--task-id --file" -- "$current") ) ;;
                make-notes) COMPREPLY=( $(compgen -W "--task-id --start-timer" -- "$current") ) ;;
                make-workspace) COMPREPLY=( $(compgen -W "--task-id" -- "$current") ) ;;
                push-notes) COMPREPLY=( $(compgen -W "--task-id --file --date --all --select --dry-run" -- "$current") ) ;;
                set-status) COMPREPLY=( $(compgen -W "--task-id --status" -- "$current") ) ;;
                complete) COMPREPLY=( $(compgen -W "--task-id" -- "$current") ) ;;
                create) COMPREPLY=( $(compgen -W "--list-id --name --description --assignee-id --tag --yes" -- "$current") ) ;;
                push-todo) COMPREPLY=( $(compgen -W "--file --list-id --tag --dry-run" -- "$current") ) ;;
                add-comment) COMPREPLY=( $(compgen -W "--task-id --comment --codeblock --bulletlist" -- "$current") ) ;;
                get-comments) COMPREPLY=( $(compgen -W "--task-id --export" -- "$current") ) ;;
            esac
            return
        fi
        return
    fi

    case "$previous" in
        --tasks|-t)
            COMPREPLY=( $(compgen -W "$task_actions" -- "$current") )
            return
            ;;
        --interval)
            COMPREPLY=( $(compgen -W "10 30 60 120 300" -- "$current") )
            return
            ;;
        --date)
            COMPREPLY=( $(compgen -W "$(date +%F)" -- "$current") )
            return
            ;;
    esac

    if [[ "$current" == --* ]]; then
        COMPREPLY=( $(compgen -W "$options" -- "$current") )
        return
    fi

    if [[ "$previous" == "--time-start" || "$previous" == "--time-log" || "$previous" == "--notes" || "$words" == *" --notes "* ]]; then
        local task_options
        task_options="$(_clctl_cached_task_ids)"
        if [[ "$words" == *" --notes "* ]]; then
            task_options+=$'\n--start'
        fi
        mapfile -t COMPREPLY < <(compgen -W "$task_options" -- "$current")
        return
    fi

    COMPREPLY=( $(compgen -W "$options" -- "$current") )
}

# complete -o bashdefault -o default -F _clctl_completion clctl
unset -f clctl 2>/dev/null
if command -v clctl >/dev/null 2>&1; then
    source <(clctl completion bash)
fi
