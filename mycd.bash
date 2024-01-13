#!/bin/bash

# Author:  Nicholas Hubbard
# WWW:     https://github.com/NicholasBHubbard/mycd
# License: MIT

MYCD_HIST_LENGTH=${MYCD_HIST_LENGTH:-15}

mycd() {

    if [[ $# -gt 1 ]]; then
        >&2 printf "mycd: too many arguments\n"
        return 1
    fi

    local histfile="$HOME/.mycd-dir-hist"

    [[ -f $histfile ]] || (:> "$histfile")

    chmod 0644 "$histfile"

    if ! [[ -r $histfile && -w $histfile ]]; then
        >&2 printf "mycd: you do not have read+write permission on %s\n" "$histfile"
        return 1
    fi

    local arg="$1" newdir histlength=0

    if [[ $arg =~ ^-([1-9][0-9]*)$ ]]; then
        local histnum=${BASH_REMATCH[1]}

        declare -A dirhist

        while read -r dir; do
            ((histlength++))
            dirhist[$histlength]=$dir
        done < "$histfile"

        if [[ -v dirhist[$histnum] ]]; then
            newdir=${dirhist[$histnum]}
        else
            >&2 printf "mycd: %s not in range 1-%s\n" "$histnum" "$histlength"
            return 1
        fi
    elif [[ $arg == '--' ]]; then
        nl "$histfile"
        return 0
    elif [[ -z $arg ]]; then
        newdir="$HOME"
    else
        newdir="$arg"
    fi

    builtin cd "$newdir" || return 1
    newdir="$PWD"

    local tmp
    tmp=$(mktemp /tmp/mycd-dir-hist.XXXXXXXXXX)
    cp -dp "$histfile" "$tmp"

    cat <(printf "%s\n" "$newdir") <(grep -vFx "$newdir" "$histfile") \
    | head -n "$MYCD_HIST_LENGTH" > "$tmp" && cp -dp "$tmp" "$histfile"

    [[ -f $tmp ]] && rm "$tmp"

    return 0
}
