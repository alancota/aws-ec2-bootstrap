################################################################################################
# Credit: some functions copied from the Homebrew install.sh script
# that can be found here: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
################################################################################################

abort() {
    printf "%s\n" "$@" >&2
    exit 1
}

# string formatters
if [[ -t 1 ]]; then
    tty_escape() { printf "\033[%sm" "$1"; }
else
    tty_escape() { :; }
fi

# Custom colors
# Example: echo "${tty_reset}Installing ${tty_bold}${tty_yellow}"${arg}"${tty_reset}${tty_reset}:"
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_yellow="$(tty_mkbold 93)"
tty_green="$(tty_mkbold 32)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
    local arg
    printf "%s" "$1"
    shift
    for arg in "$@"; do
        printf " "
        printf "%s" "${arg// /\ }"
    done
}

chomp() {
    printf "%s" "${1/"$'\n'"/}"
}

warn() {
    printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")" >&2
}

p_msg() {
    printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

wait_for_user() {
    local c
    echo
    echo "Press ${tty_bold}RETURN${tty_reset}/${tty_bold}ENTER${tty_reset} to continue or any other key to abort:"
    getc c
    # we test for \r and \n because some stuff does \r instead
    if ! [[ "${c}" == $'\r' || "${c}" == $'\n' ]]; then
        exit 1
    fi
}

getc() {
    local save_state
    save_state="$(/bin/stty -g)"
    /bin/stty raw -echo
    IFS='' read -r -n 1 -d '' "$@"
    /bin/stty "${save_state}"
}
