#! bash oh-my-bash.module

_autoclean_completion() {
    local compspec compcmds compcmd
    readarray -t compcmds < <( complete | while read -r -a compspec; do
        echo "${compspec[$((${#compspec[*]}-1))]}"
    done )
    # _omb_util_command_exists "$compcmd" || complete -r "$compcmd"
    for compcmd in "${compcmds[@]}"; do
        _omb_util_command_exists "$compcmd" && continue
        [[ $compcmd == -D ]] && continue
        complete -r "$compcmd"
    done
}

_omb_util_add_prompt_command _autoclean_completion
