#!/bin/bash

# Requires: bash_cmd_extd, tmux, fzf, fs_nav_extd, yq

export TMUX_CONF=$HOME/.tmux.conf
export TMUX_DIR=$HOME/.tmux
export TX_DIR=$TMUX_DIR/tx
_TX_SH=$(readlink -f "${BASH_SOURCE[0]}")

_tx_all_sessions(){
    find $TX_DIR/sessions -type f | awk -F'sessions/' '{print$2}'
}

_tx_build_session(){
    s_name=$1
    s_dir=$2
    local main_cmd="${3:-if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git pull; fi; clear}"
    local switch_client="${4:-true}"
    tmux new-session -d -s "$s_name" -n "main"
    tmux send-keys -t "${s_name}:main" "cd $s_dir" ENTER
    tmux send-keys -t "${s_name}:main" "$main_cmd" ENTER
    tmux new-window -t "$s_name" -n "term" -c "$s_dir"
    tmux send-keys -t "${s_name}:term" "cd $s_dir; clear" ENTER
    tmux select-window -t "${s_name}:main"
    if [ "$switch_client" = true ]; then
        tmux switch-client -t "$s_name"
    fi
}


_tx_select_session(){
    all_sessions=$(_tx_all_sessions)
    s_name="$1"
    session=$(grep "${s_name}\.yaml$"<<<$all_sessions)
    if [ -z "$s_name" ]; then
        session=$(fzf<<<$all_sessions)
    fi
    echo $session
}

tx(){
    arg="$1"
    if [ -z "$arg" ]; then
        arg=$(fzf<<<$(tr ' ' '\n'<<<"$(ls $TX_DIR/opts)"))
    fi
    shift
    case "$arg" in
        "add" | "-a")
            tx_add "$@";;
        "bind" | "-b")
            tx_bind "$@";;
        "create" | "-c")
            tx_create "$@";;
        "delete" | "-d")
            tx_delete "$@";;
        "find" | "-f")
            tx_session;;
        "help" | "-h")
            tx_help;;
        "init" | "-i")
            tx_init;;
        "load" | "-l")
            tx_load "$@";;
        "print" | "-p")
            tx_print;;
        "restore" | "-r")
            tx_restore;;
        "save")
            tx_save;;
        "session" | "-s")
            tx_session "$@";;
        "unbind" | "-u")
            tx_unbind "$@";;
        *)
            echo "Unknown command: '$arg'" ;;
    esac
}

_tx_completion(){
    local current command
    current=${COMP_WORDS[COMP_CWORD]}

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "add bind create delete find help init load print restore save session unbind" -- "$current") )
        return
    fi

    command=${COMP_WORDS[1]}
    case "$command" in
        create | -c)
            compopt -o filenames 2>/dev/null
            mapfile -t COMPREPLY < <(compgen -d -- "$current")
            ;;
    esac
}

complete -F _tx_completion tx

tx_add(){
    all_sessions=$(_tx_all_sessions)
    session=$1
    if [ -z "$session" ]; then
        session="$(basename $PWD):$PWD"
    fi
        echo "Name: ${session##*/}"
    s_name=${session%%:*}
    s_dir=${session##*:}
    session_exists=$(grep "${s_name}\.yaml$"<<<$all_sessions)
    if [ -z "$session_exists" ]; then
        echo "Adding new session '$session'"
        echo "dir: $s_dir" >> ~/.tmux/tx/sessions/normal/$s_name.yaml
    else
        echo "Session with name $s_name already exists. Doing nothing."
    fi
}

tx_create(){
    if [ "$#" -gt 2 ]; then
        echo "Usage: tx create [s_name] [s_dir]"
        return 1
    fi

    local s_name=""
    local s_dir=""
    local arg
    for arg in "$@"; do
        if [ -d "$arg" ]; then
            if [ -n "$s_dir" ]; then
                echo "Only one session directory may be provided."
                return 1
            fi
            s_dir=$(realpath "$arg")
        elif [[ "$arg" == */* ]]; then
            echo "Session directory does not exist: $arg"
            return 1
        elif [ -n "$s_name" ]; then
            echo "Only one session name may be provided."
            return 1
        else
            s_name=$arg
        fi
    done

    if [ -z "$s_name" ]; then
        read -r -p "Session name: " s_name
    fi
    if [ -z "$s_name" ]; then
        echo "A session name is required."
        return 1
    fi
    if [[ "$s_name" == */* || "$s_name" == *" "* ]]; then
        echo "Session name must not contain '/' or spaces."
        return 1
    fi

    if [ -z "$s_dir" ]; then
        while true; do
            read -r -p "Session directory: " arg
            if [ -d "$arg" ]; then
                s_dir=$(realpath "$arg")
                break
            fi
            echo "Directory does not exist: $arg"
        done
    fi

    all_sessions=$(_tx_all_sessions)
    if grep -Eq "(^|/)${s_name}\.yaml$" <<<"$all_sessions"; then
        echo "Session with name $s_name already exists. Doing nothing."
        return 1
    fi

    while true; do
        read -r -p "Create session as init or normal [normal]: " session_type
        session_type=${session_type:-normal}
        case "$session_type" in
            init | normal)
                break ;;
            *)
                echo "Choose init or normal." ;;
        esac
    done

    echo "dir: $s_dir" > "$TX_DIR/sessions/$session_type/$s_name.yaml"
    echo "Created $session_type session '$s_name' for '$s_dir'"

    read -r -p "Create a bind for $s_name? [y/N]: " create_bind
    case "$create_bind" in
        y | Y | yes | YES)
            tx_bind "$s_name" ;;
    esac
}

tx_bind(){
    all_sessions=$(_tx_all_sessions)
    # TODO - need to be able to parse argument - either a bind number or session name or both or 'list' to list current binds
    current_binds=$(awk '/bind -n M-[0-9] switch -t/{printf "%s - %s\n",$3,$6}' $TMUX_CONF)
    session_select=""
    bind_select=""
    case "$1" in
        "list" | "l")
            echo "Current binds"
            echo "$current_binds"
            return ;;
        [0-9])
            bind_select="M-$1" ;;
        *)
            session_select=$1 ;;
    esac
    case "$2" in
        [0-9])
            bind_select="M-$2" ;;
        *)
            session_select=$2 ;;
    esac
    sessions_remaining=$(for s in $(awk -F/ '{print$2}'<<<$all_sessions); do if ! grep -q "${s//.yaml/}"<<<"$current_binds"; then echo "${s//.yaml/}"; fi;done)
    current_sessions=$(tmux list-sessions | awk -F: '{print$1}')
    current_sessions_without_bind=$(for s in $current_sessions; do if ! grep -q "$s"<<<"$current_binds"; then echo "$s"; fi;done)
    session_selects=$(printf '%s\n' "$sessions_remaining" "$current_sessions_without_bind" | awk 'NF && !seen[$0]++')
    if [[ ! -z $session_select ]]; then
        if grep -q "$session_select"<<<"$current_binds"; then
            echo "Session $session_select already bound to $(awk -F: '{print$2}'<<<$(grep "$session_select"<<<"$current_binds"))"
            return
        fi
        if ! grep -q "$session_select"<<<$session_selects; then
            echo "Session $session_select doesn't exist"
            return
        fi
    else
        session_select=$(fzf<<<$session_selects)
        if [ -z $session_select ]; then
            echo "Doing nothing."
            return
        fi
    fi
    binds_remaining=$(for i in $(seq 0 9); do if ! grep -q "M-$i"<<<$current_binds; then echo "M-$i"; fi;done)
    if [ -z "$binds_remaining" ]; then
        echo "No binds remaining. Please unbind something first."
    else
        if [[ ! -z $bind_select ]]; then
            if grep -q "$bind_select"<<<"$current_binds"; then
                echo "Session $bind_select already bound to $(awk -F: '{print$1}'<<<$(grep "$bind_select"<<<"$current_binds"))"
                return
            fi
        else
            bind_select=$(fzf<<<$binds_remaining)
        fi
        if [[ ! -z $bind_select ]]; then
            echo "Binding session $session_select to $bind_select"
            echo "bind -n $bind_select switch -t \"$(awk -F: '{print$1}'<<<$session_select)\"" >> $TMUX_CONF
            tmux source $TMUX_CONF
        else
            echo "Doing nothing."
        fi
    fi
    current_binds=$(awk '/bind -n M-[0-9] switch -t/{printf "%s - %s\n",$3,$6}' $TMUX_CONF)
    echo "Current binds:"
    echo "$current_binds"
}

txconf(){
    tmux new-window nvim $TMUX_CONF
    tmux source $TMUX_CONF
}

tx_delete(){
    session=$(_tx_select_session $1)
    rm $TX_DIR/sessions/$session
    echo "Removed '$session' from tx"
    current_binds=$(awk '/bind -n M-[0-9] switch -t/{printf "%s - %s\n",$3,$6}' $TMUX_CONF)
    if grep -q "$session" <<<$current_binds; then
        tx_unbind "$session"
    fi
}

tx_help(){
    local opts_dir="$TX_DIR/opts_dir"
    local opt_file opt_name

    if [ -n "$1" ]; then
        opt_file="$opts_dir/$1"
        if [ ! -f "$opt_file" ]; then
            echo "No help available for '$1'."
            return 1
        fi

        echo "tx - tmux session manager cli"
        echo
        echo "Name: $1"
        echo "Description:"
        yq -r '.desc[]? // empty' "$opt_file"
        echo "Usage:"
        yq -r '.usage[]? // empty' "$opt_file"
        return
    fi

    echo "tx - tmux session manager cli"
    echo "Options:"
    for opt_file in "$opts_dir"/*; do
        [ -f "$opt_file" ] || continue
        opt_name=${opt_file##*/}
        echo
        echo "Name: $opt_name"
        echo "Description:"
        yq -r '.desc[]? // empty' "$opt_file"
        echo "Usage:"
        yq -r '.usage[]? // empty' "$opt_file"
    done
}

tx_init(){
    all_sessions=$(_tx_all_sessions)
    active_sessions=$(tmux list-sessions)
    current_session=$(tmux display-message -p '#S')
    for session in $(grep 'init'<<<$all_sessions); do
        s_file=${session##*/}
        s_name=${s_file//.yaml/}
        s_dir=$(yq '.dir' $TX_DIR/sessions/$session)
        session_exists=$(grep "^${s_name}:"<<<$active_sessions)
        if [ -z "$session_exists" ]; then
            echo "Creating '$s_name'"
            if [ "$s_name" = "notes" ]; then
                _tx_build_session "$s_name" "$s_dir" "nvnotes" false
            else
                _tx_build_session "$s_name" "$s_dir" "" false
            fi
        fi
    done
    rm ~/.tmuxinit_tmp 2>/dev/null
    cat >>~/.tmuxinit_tmp<<EOF
while [ "\$(grep '$current_session'<<<\$(tmux list-sessions))" == "\$(grep 'attached'<<<\$(tmux list-sessions))" ]; do
    sleep 1
done
tmux kill-session -t $current_session
EOF
    chmod +x ~/.tmuxinit_tmp
    tmux send-keys -t "$s_name" '~/.tmuxinit_tmp' ENTER
    session_exists=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -x "notes")
    if [ "$session_exists" ]; then
        s_name="notes"
    fi
    tmux switch -t $s_name
}

tx_load(){
    session=$(_tx_select_session $1)
    if [ -z "$session" ]; then
        echo "Doing nothing."
        return
    fi
    s_file=${session##*/}
    s_name=${s_file//.yaml/}
    s_dir=$(yq '.dir' $TX_DIR/sessions/$session)
    session_exists=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -x "$s_name")
    if [ -z "$session_exists" ]; then
        _tx_build_session "$s_name" "$s_dir"
    else
        tmux switch -t "$s_name"
    fi
}

tx_print(){
    all_sessions=$(_tx_all_sessions)
    echo ""
    echo "TX All Sessions:"
    for session in $all_sessions; do
        s_file=${session##*/}
        echo "----"
        echo "Name: ${s_file//.yaml/}"
        echo "Type: ${session%%/*}"
        echo "Dir:  $(yq '.dir' $TX_DIR/sessions/$session)"
    done
    echo "----"
}

_tx_resurrect_script(){
    local script="$HOME/.tmux/plugins/tmux-resurrect/scripts/$1.sh"
    if [ ! -x "$script" ]; then
        echo "tmux-resurrect is not installed. Add it through TPM, then run prefix + I in tmux."
        return 1
    fi
    printf '%s\n' "$script"
}

_tx_save_nvim_sessions(){
    local panes pane_id pane_command pane_dir signal
    panes=$(tmux list-panes -a -F '#{pane_id}|#{pane_current_command}|#{pane_current_path}') || return 1
    while IFS='|' read -r pane_id pane_command pane_dir; do
        case "$pane_command" in
            nvim | nvim-*)
                signal="tx-save-nvim-${pane_id//%/p}"
                tmux wait-for -L "$signal" || return 1
                if ! tmux send-keys -t "$pane_id" 'C-\' C-n; then
                    tmux wait-for -U "$signal"
                    return 1
                fi
                if ! tmux send-keys -t "$pane_id" -l ":silent! mksession! Session.vim | call system('tmux wait-for -U $signal')"; then
                    tmux wait-for -U "$signal"
                    return 1
                fi
                if ! tmux send-keys -t "$pane_id" Enter; then
                    tmux wait-for -U "$signal"
                    return 1
                fi
                if ! timeout 15s tmux wait-for -L "$signal"; then
                    tmux wait-for -U "$signal"
                    echo "Timed out saving Neovim session in pane $pane_id."
                    return 1
                fi
                tmux wait-for -U "$signal" || return 1
                if [ ! -s "$pane_dir/Session.vim" ]; then
                    echo "Neovim did not write $pane_dir/Session.vim."
                    return 1
                fi
                ;;
        esac
    done <<< "$panes"
}

tx_save(){
    local script snapshot_dir last_snapshot pane_info pane_id pane_title save_status
    local -a blank_title_panes=()
    script=$(_tx_resurrect_script save) || return 1
    snapshot_dir="$TX_DIR/snapshot"
    tmux set-option -g @resurrect-dir "$snapshot_dir" || return 1
    mkdir -p "$snapshot_dir"
    _tx_save_nvim_sessions || return 1
    pane_info=$(tmux list-panes -a -F '#{pane_id}|#{pane_title}') || return 1
    while IFS='|' read -r pane_id pane_title; do
        if [ -z "$pane_title" ]; then
            if ! tmux select-pane -t "$pane_id" -T " "; then
                for pane_id in "${blank_title_panes[@]}"; do
                    tmux select-pane -t "$pane_id" -T ""
                done
                return 1
            fi
            blank_title_panes+=("$pane_id")
        fi
    done <<< "$pane_info"
    save_status=0
    bash "$script" || save_status=$?
    for pane_id in "${blank_title_panes[@]}"; do
        tmux select-pane -t "$pane_id" -T "" || return 1
    done
    [ "$save_status" -eq 0 ] || return "$save_status"
    last_snapshot=$(readlink -f "$snapshot_dir/last") || {
        echo "tmux-resurrect did not create the latest snapshot."
        return 1
    }
    local -a snapshots=("$snapshot_dir"/tmux_resurrect_*.txt)
    local snapshot
    for snapshot in "${snapshots[@]}"; do
        if [ -f "$snapshot" ] && [ "$snapshot" -ef "$last_snapshot" ]; then
            continue
        fi
        rm -f -- "$snapshot"
    done
    echo "Saved the current tmux state to $last_snapshot"
}

tx_restore(){
    _tx_resurrect_script restore >/dev/null || return 1
    if [ ! -f "$TX_DIR/snapshot/last" ]; then
        echo "No tmux snapshot found. Run 'tx save' before restarting WSL."
        return 1
    fi
    # On a fresh tmux server tmux-resurrect kills session "0" once the saved
    # panes exist. Running the restore in this pane's shell died with it, so
    # nothing was restarted until a second 'tx restore'. Run it from the tmux
    # server instead so it survives losing this pane.
    local log="$TX_DIR/snapshot/restore.log" restore_status=0
    tmux run-shell "bash -c $(printf '%q' "source $(printf '%q' "$_TX_SH") && _tx_restore_run") >$(printf '%q' "$log") 2>&1" || restore_status=$?
    cat "$log"
    return "$restore_status"
}

_tx_restore_run(){
    local script target process directory current_command command summary resurrect_processes restore_status=0
    local app_count=0 started_count=0 running_count=0 missing_count=0
    script=$(_tx_resurrect_script restore) || return 1
    tmux set-option -g @resurrect-dir "$TX_DIR/snapshot" || return 1
    # The loop below restarts the apps. tmux-resurrect would also type some of
    # them into shells that are still starting, so they'd be launched twice.
    resurrect_processes=$(tmux show-option -gqv @resurrect-processes)
    tmux set-option -g @resurrect-processes false || return 1
    bash "$script" || restore_status=$?
    if [ -n "$resurrect_processes" ]; then
        tmux set-option -g @resurrect-processes "$resurrect_processes"
    else
        tmux set-option -gu @resurrect-processes
    fi
    [ "$restore_status" -eq 0 ] || return "$restore_status"

    while IFS=$'\t' read -r target process directory; do
        if ! current_command=$(tmux display-message -p -t "$target" '#{pane_current_command}' 2>/dev/null); then
            printf "tx restore: saved pane %s is missing.\n" "$target" >&2
            ((missing_count+=1))
            continue
        fi
        ((app_count+=1))
        if [ "$current_command" = "$process" ]; then
            ((running_count+=1))
            continue
        fi
        case "$current_command" in
            bash | sh | zsh | fish)
                case "$process" in
                    nvim)
                        [ -s "${directory#:}/Session.vim" ] || continue
                        command='nvim -S' ;;
                    claude)
                        command='claude --continue' ;;
                    k9s)
                        command='k9s' ;;
                    *)
                        ((missing_count+=1))
                        continue ;;
                esac
                if tmux send-keys -t "$target" -l "$command" && tmux send-keys -t "$target" Enter; then
                    ((started_count+=1))
                else
                    printf "tx restore: could not start %s in %s.\n" "$process" "$target" >&2
                    ((missing_count+=1))
                fi
                ;;
            *)
                printf "tx restore: left %s in %s unchanged (running %s).\n" "$process" "$target" "$current_command" >&2
                ((missing_count+=1))
                ;;
        esac
    done < <(awk -F '\t' '$1 == "pane" && ($10 == "nvim" || $10 == "claude" || $10 == "k9s") { printf "%s:%s.%s\t%s\t%s\n", $2, $3, $6, $10, $8 }' "$TX_DIR/snapshot/last")
    summary=$(printf "tx restore: %d saved app panes; %d already running, %d commands sent, %d unavailable." "$app_count" "$running_count" "$started_count" "$missing_count")
    echo "$summary"
    tmux display-message "$summary"
    [ "$missing_count" -eq 0 ]
}

tx_session(){
    directory="$1"
    if [ -z "$directory" ]; then
        directory=$(_fzfdir)
    fi
    s_name=$(basename "$directory")
    s_dir="$(realpath $directory)"
    if tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -qx "$s_name"; then
        tmux switch-client -t "$s_name"
        exit 0
    fi
    _tx_build_session "$s_name" "$s_dir"
}

tx_unbind(){
    for arg in $@; do
        if [ "$arg" == "-h" ]; then
            tx_help "unbind"
            return
        fi
    done
    current_binds=$(awk '/bind -n M-[0-9] switch -t/{printf "%s - %s\n",$3,$6}' $TMUX_CONF)
    select=""
    if [[ ! -z $1 ]];then
        select=$(grep "$1"<<<$current_binds)
        if [ -z "$select" ]; then
            echo "Bind $1 does not exist. Current binds:"
            echo "$current_binds"
        fi
    else
        select=$(fzf<<<$current_binds)
    fi
    unbind_select=$(awk '{print$1}'<<<$select)
    echo "Unbinding $unbind_select (was $(awk '{print$3}'<<<$select)).."
    sed -i "s/bind -n $unbind_select switch -t.*/unbind -n $unbind_select/" $TMUX_CONF
    tmux source $TMUX_CONF
    sed -i "/unbind -n $unbind_select/d" $TMUX_CONF
    tmux source $TMUX_CONF
    current_binds=$(awk '/bind -n M-[0-9] switch -t/{printf "%s - %s\n",$3,$6}' $TMUX_CONF)
    echo "Current binds:"
    echo "$current_binds"
}
