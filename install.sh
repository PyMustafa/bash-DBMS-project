#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# ensure script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (e.g., using sudo)"
    exit 1
fi

# install gum
if command_exists gum; then
    echo "gum is already installed"
else
    echo "gum is not installed, adding the Charm repository..."

    # add Charm repository for gum
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list

    # update package list and install gum
    echo "Installing gum..."
    apt update && apt install -y gum
fi

# check tput availability
if command_exists tput; then
    echo "tput is already available"
else
    echo "tput is not installed, but it should be pre-installed on your system"
fi

echo "All dependencies are installed and ready!"