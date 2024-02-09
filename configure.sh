#!/bin/sh

# Load custom functions
source "$(dirname $0)/functions.zsh"

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

    Set ZSH_THEME="powerlevel10k/powerlevel10k" in ~/.zshrc
else
    p_msg "Powerlevel10k installation skipped"
fi

p_msg "Reloading the .zshrc file"
source ~/.zshrc
