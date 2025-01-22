#!/bin/bash

# ensure script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (e.g., using sudo)"
    exit 1
fi

# install gum
if command -v gum &>/dev/null; then
    echo "gum is already installed"
else
    echo "Installing gum..."
    sudo apt update && sudo apt install -y gum
fi

# check tput availability
if command -v tput &>/dev/null; then
    echo "tput is already available"
else
    echo "tput is not installed, but it should be pre-installed on your system"
fi

echo "All dependencies are installed and ready!"
