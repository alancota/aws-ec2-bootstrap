#!/bin/bash

# Parse arguments from URL
args=$(echo "$1" | awk -F'=' '{print $2}')

ALIASES="https://raw.githubusercontent.com/alancota/aws-ec2-bootstrap/main/aliases.txt"
FOLDERS="https://github.com/alancota/aws-ec2-bootstrap/blob/main/folders.txt"
PACKAGES="https://github.com/alancota/aws-ec2-bootstrap/blob/main/packages.txt"

# Function to display usage
usage() {
    echo "Usage: $0 [-c|--change-hostname <hostname>] [-a|--all] [-i|--install <options>] [-h|--help]"
    echo "Available options for -i/--install:"
    echo "  - ohmyzsh"
    echo "  - nerdfonts"
    echo "  - pk10"
    echo "  - docker"
    echo "  - pyenv"
    echo "  - all"
    exit 1
}

# Function to prompt for the ZSH theme
prompt_for_zsh_theme() {
    read -p "Change ZSH Theme? (default=powerlevel10k): " theme
    if [ -z "$theme" ]; then
        theme="powerlevel10k/powerlevel10k"
    fi
}

# Function to update ZSH_THEME in .zshrc file
update_zsh_theme() {
    #local theme="powerlevel10k/powerlevel10k"

    prompt_for_zsh_theme

    echo "ZSH Theme: $theme"

    # Check if .zshrc file exists
    if [ -f "$HOME/.zshrc" ]; then
        # Use sed to replace the value of ZSH_THEME
        sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$HOME/.zshrc"
        echo "Updated ZSH_THEME to '$theme' in .zshrc"
    else
        echo "Error: .zshrc file not found in $HOME directory."
        exit 1
    fi
}

# Function to prompt for hostname
prompt_for_hostname() {
    read -p "Enter new hostname: " hostname
    if [ -z "$hostname" ]; then
        echo "Error: Please provide a new hostname."
        exit 1
    fi
}

# Function to reload the .zshrc file
reload_zshrc() {
    # Check if .zshrc file exists
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc"
    fi
}

# Function to install oh-my-zsh
install_oh_my_zsh() {
    echo "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# Function to install docker-engine
install_docker_engine() {
    echo "Installing docker-engine"
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    # Install the latest version [01/25 2:51 PM - ac]:
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Post-installation steps
    # More: https://docs.docker.com/engine/install/linux-postinstall/

    # The following steps will allow the user to run docker without sudo
    # Create a Docker group (if not yet created)
    echo "Adding the current user $USER to the Docker gropup"
    sudo groupadd docker

    # Add the current user to the Docker group
    sudo usermod -aG docker $USER

    # Configure Docker to start with the systemd
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    echo "Testing if the user $USER can run docker without sudo"
    docker run hello-world

}

# Function to append aliases from aliases.txt to ~/.zshrc file
append_aliases() {
    local zshrc_file="$HOME/.zshrc"
    local aliases_file="$ALIASES"

    # Check if aliases.txt file exists
    if [ -f "$aliases_file" ]; then
        # Check if ~/.zshrc file exists
        if [ -f "$zshrc_file" ]; then
            # Append aliases from aliases.txt to ~/.zshrc
            cat "$aliases_file" >>"$zshrc_file"
            echo "Aliases appended to ~/.zshrc."
        else
            echo "Error: ~/.zshrc file not found."
            exit 1
        fi
    else
        echo "Error: aliases.txt file not found."
        exit 1
    fi
}

# Function to create a backup of ~/.zshrc file
backup_zshrc() {
    echo "Creating backup of ~/.zshrc"
    local zshrc_file="$HOME/.zshrc"

    # Check if ~/.zshrc file exists
    if [ -f "$zshrc_file" ]; then
        local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
        local backup_file=".zshrc_bkp_$timestamp"
        cp "$zshrc_file" "$backup_file"
        echo "Backup of ~/.zshrc created: $backup_file"
    else
        echo "No existing ~/.zshrc file found."
    fi
}

# Function to prepend Pyenv configuration to ~/.zshrc file
add_pyenv_configuration() {
    echo "Adding Pyenv configuration to ~/.zshrc"
    local zshrc_file="$HOME/.zshrc"
    local timestamp=$(date +"%m/%d/%Y %T")
    local configuration="# Timestamp: $timestamp
## pyenv configs
export PYENV_ROOT=\"\$HOME/.pyenv\"
export PATH=\"\$PYENV_ROOT/bin:\$PATH\"

if command -v pyenv 1>/dev/null 2>&1; then
  eval \"\$(pyenv init -)\"
fi"

    # Check if ~/.zshrc file exists
    if [ -f "$zshrc_file" ]; then
        # Create a backup of ~/.zshrc file
        backup_zshrc

        # Prepend configuration to ~/.zshrc
        echo "$configuration" | cat - "$zshrc_file" >temp && mv temp "$zshrc_file"
        echo "Configuration prepended to ~/.zshrc."
    else
        echo "No existing ~/.zshrc file found. Creating a new one..."
        echo "$configuration" >"$zshrc_file"
        echo "Configuration added to new ~/.zshrc file."
    fi
}

# Function to install Python
install_pyenv() {
    echo "Installing Python uving Pyenv..."
    sudo apt-get update
    git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
    add_pyenv_configuration
}

# Function to install Ubuntu font management package and nerd fonts
install_nerdfonts() {
    echo "Installing Ubuntu font management package and nerd fonts"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh)"

    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf

    echo "Refreshing local fonts cache..."
    fc-cache -fv
}

# Function to install Powerlevel10k
install_powerlevel10k() {

    echo "Installing Powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    # Call function to update ZSH_THEME
    update_zsh_theme

    # Reload the .zshrc file
    reload_zshrc
}

# Function to install all options
install_all() {
    echo "Installing all available options..."
    install_oh_my_zsh
    install_nerdfonts
    install_powerlevel10k
}

# This function will run allways, independent of the arguments passed

# Function to update Ubuntu packages
update_packages() {
    echo "Updating apt"
    sudo apt update -y

    echo "Upgrading packages"
    sudo apt upgrade -y
}

# Function to install Ubuntu packages
# Function to install packages from packages.txt file
install_packages() {
    # Check if packages.txt file exists
    if [ -f "$PACKAGES" ]; then
        # Read package names from packages.txt file and install them using apt
        sudo apt install -y $(cat packages.txt)
        echo "Packages installed successfully."
    else
        echo "Error: packages.txt file not found."
        exit 1
    fi
}

# Function to create folders from folders.txt file
create_folders() {
    # Check if folders.txt file exists
    if [ -f "$FOLDERS" ]; then
        # Read folder names from folders.txt file and create them
        while IFS= read -r folder_name; do
            mkdir -p "$folder_name"
            echo "Folder '$folder_name' created."
        done <folders.txt
        echo "Folders created successfully."
    else
        echo "Error: folders.txt file not found."
        exit 1
    fi
}

# Function with all the common installation steps
install() {
    echo "Performing common installation steps"
    update_packages
    install_packages
    create_folders
}

# Function to install options
install_options() {
    for option in $1; do
        case "$option" in
        ohmyzsh) install_oh_my_zsh ;;
        nerdfonts) install_nerdfonts ;;
        pk10) install_powerlevel10k ;;
        docker) install_docker ;;
        pyenv) install_pyenv ;;
        all) install_powerlevel10k ;;
        *)
            echo "Error: Unknown installation option '$option'."
            exit 1
            ;;
        esac
    done
}

# Initialize variables
change_hostname=false
all=false
install_options_list=""

# Parse options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -c | --change-hostname)
        change_hostname=true
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            hostname="$2"
            shift
        else
            prompt_for_hostname
        fi
        ;;
    -a | --all) all=true ;;
    -i | --install)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            install_options_list="$2"
            shift
        else
            echo "Error: Please provide installation options after the -i/--install argument."
            usage
        fi
        ;;
    -h | --help) usage ;;
    *)
        echo "Error: Unknown option '$1'."
        usage
        ;;
    esac
    shift
done

# Check if no arguments provided
if ! $change_hostname && ! $all && [ -z "$install_options_list" ]; then
    echo "No arguments provided."
    usage
fi

# If -i option is provided without any options, display available options
if [ -z "$install_options_list" ]; then
    echo "Available options for -i/--install:"
    echo "  - ohmyzsh"
    echo "  - nerdfonts"
    echo "  - pk10"
    echo "  - docker"
    echo "  - pyenv"
    echo "  - all"
    exit 1
fi

# Install options
if $all; then
    # Perform common installation steps
    install

    # Install all options
    install_options "ohmyzsh nerdfonts pk10"
elif [ -n "$install_options_list" ]; then
    # Perform common installation steps
    install

    # Install selected options
    install_options "$install_options_list"
fi

# Change hostname if provided
if $change_hostname; then
    echo "Changing the hostname from $(hostname -f) to: $hostname"
    sudo hostnamectl set-hostname "$newhostname"
fi
