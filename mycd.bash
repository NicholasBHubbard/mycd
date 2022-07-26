# Author:  Nicholas Hubbard
# WWW:     https://github.com/NicholasBHubbard/mycd
# License: MIT

MYCD_HIST_FILE=${MYCD_HIST_FILE:-"$HOME/.mycd-dir-hist"}
MYCD_HIST_LENGTH=${MYCD_HIST_LENGTH:-15}

function mycd() {

    if [[ $# -gt 1 ]]; then
        >&2 printf "mycd: too many arguments\n"
        return 1
    fi

    [[ -f $MYCD_HIST_FILE ]] || (touch "$MYCD_HIST_FILE" && chmod 0666 "$MYCD_HIST_FILE")

    if ! [[ -r $MYCD_HIST_FILE && -w $MYCD_HIST_FILE ]]; then
        >&2 printf "mycd: you do not have read+write permission on %s\n" "$MYCD_HIST_FILE"
        return 1
    fi

    local arg="$1" newdir histlength=0

    if [[ $arg =~ ^-([1-9][0-9]*)$ ]]; then
        local histnum=${BASH_REMATCH[1]}

        declare -A dirhist

        while read -r dir; do
            ((histlength++))
            dirhist[$histlength]=$dir
        done < "$MYCD_HIST_FILE"

        if [[ -v dirhist[$histnum] ]]; then
            newdir=${dirhist[$histnum]}
        else
            >&2 printf "mycd: %s not in range 1-%s\n" "$histnum" "$histlength"
            return 1
        fi
    elif [[ $arg == '--' ]]; then
        nl "$MYCD_HIST_FILE"
        return 0
    elif [[ -z $arg ]]; then
        newdir="$HOME"
    else
        newdir="$arg"
    fi

    builtin cd "$newdir" || return 1
    newdir="$PWD"

    local tmp
    tmp=$(mktemp /tmp/mycd.XXXXXXXXXX)

    cat <(printf "%s\n" "$newdir") <(grep -vFx "$newdir" "$MYCD_HIST_FILE") \
    | head -n "$MYCD_HIST_LENGTH" > "$tmp" && mv "$tmp" "$MYCD_HIST_FILE"

    [[ -f $tmp ]] && rm "$tmp"

    return 0
}
