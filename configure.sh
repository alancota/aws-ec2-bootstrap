#!/bin/sh

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
#----------------------------------------------------------------

p_msg "Starting the configuration of this new Ubuntu EC2 instance..."

# Set variables with received arguments
_hostname="$(hostname)"
_new-hostname="$1"

p_msg "Updating apt"
@sudo apt update -y

p_msg "Upgrading packages"
@sudo apt upgrade -y

p_msg "Installing required packages"
@sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev zsh font-manager neovim

re="[^a-zA-Z_0-9\s]"
if [[ "$1" =~ $re ]]; then
    p_msg "Keeping the existing hostname: $_hostname"
else
    p_msg "Changing the hostname to: $_hostname"
    @sudo hostnamectl set-hostname "$1"
fi

p_msg "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [ "$2" == "true" ]; then
    p_msg "Installing nerd-fonts"
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf

    p_msg "Refreshing local fonts cache..."
    fc-cache -fv
else
    p_msg "Font installation skipped"
fi

p_msg "Creating the github folder"
mkdir ~/github

if [ "$3" == "true" ]; then
    p_msg "Installing Powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    Set ZSH_THEME="powerlevel10k/powerlevel10k" in https://github.com/alancota/aws-ec2-bootstrap/blob/main/configure.sh~/.zshrc
else
    p_msg "Powerlevel10k installation skipped"
fi

p_msg "Reloading the .zshrc file"
source ~/.zshrc
