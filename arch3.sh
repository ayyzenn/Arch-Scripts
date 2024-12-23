#!/bin/bash

# Arch Linux Setup Script (Inspired by LARBS)
# Automates installation and configuration of a personalized Arch Linux system.

# --------------------
# OPTIONS AND VARIABLES
# --------------------
DOTFILES_REPO="https://github.com/lukesmithxyz/voidrice.git"
PROGS_FILE="https://raw.githubusercontent.com/LukeSmithxyz/LARBS/master/static/progs.csv"
AUR_HELPER="yay"

# --------------------
# HELPER FUNCTIONS
# --------------------

# Function to check if a package is installed
is_installed() {
    pacman -Q "$1" &> /dev/null
}

# Function to install a package from the official repo
install_package() {
    if ! is_installed "$1"; then
        echo "Installing $1..."
        sudo pacman --noconfirm --needed -S "$1"
    else
        echo "$1 is already installed. Skipping."
    fi
}

# Function to install an AUR package using yay
install_aur_package() {
    if ! is_installed "$1"; then
        echo "Installing $1 from AUR..."
        $AUR_HELPER -S --noconfirm "$1"
    else
        echo "$1 is already installed. Skipping."
    fi
}

# Function to handle installation from git repos or other sources
manual_install() {
    echo "Installing $1 manually..."
    git clone "$1" "$HOME/.local/src/$(basename "$1" .git)" || {
        echo "Failed to clone $1. Skipping."
        return 1
    }
    cd "$HOME/.local/src/$(basename "$1" .git)" || exit
    makepkg --noconfirm -si
    cd ~ || exit
}

# Error handler
error() {
    echo "ERROR: $1"
    exit 1
}

# --------------------
# SYSTEM UPDATE & AUR HELPER
# --------------------

update_system() {
    echo "Updating system and installing essential tools..."
    sudo pacman --noconfirm --needed -Syu base-devel git curl wget htop || error "System update failed."
}

install_aur_helper() {
    if ! command -v $AUR_HELPER &> /dev/null; then
        echo "Installing AUR helper ($AUR_HELPER)..."
        git clone "https://aur.archlinux.org/$AUR_HELPER.git" "$HOME/.local/src/$AUR_HELPER" || error "Failed to clone AUR helper."
        cd "$HOME/.local/src/$AUR_HELPER" || exit
        makepkg --noconfirm -si || error "Failed to install AUR helper."
        cd ~ || exit
    else
        echo "$AUR_HELPER is already installed."
    fi
}

# --------------------
# PROGRAM INSTALLATION
# --------------------

install_programs() {
    echo "Downloading program list..."
    curl -Ls "$PROGS_FILE" | sed '/^#/d' > /tmp/progs.csv || error "Failed to download program list."

    echo "Installing programs from the list..."
    total=$(wc -l < /tmp/progs.csv)
    while IFS=, read -r tag program comment; do
        case "$tag" in
            A) install_aur_package "$program" ;;
            G) manual_install "$program" ;;
            P) pip install "$program" ;;
            *) install_package "$program" ;;
        esac
    done < /tmp/progs.csv
    echo "All programs installed."
}

# --------------------
# APPLY DOTFILES
# --------------------

apply_dotfiles() {
    echo "Applying dotfiles..."
    REPO_DIR="$HOME/.dotfiles"
    if [ -d "$REPO_DIR" ]; then
        echo "Dotfiles repository already exists. Pulling latest changes..."
        git -C "$REPO_DIR" pull || error "Failed to update dotfiles repository."
    else
        echo "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$REPO_DIR" || error "Failed to clone dotfiles repository."
    fi
    cp -r "$REPO_DIR"/. "$HOME/" || error "Failed to copy dotfiles."
    echo "Dotfiles applied successfully."
}

# --------------------
# CONFIGURE i3 WINDOW MANAGER
# --------------------

configure_i3() {
    echo "Configuring i3 window manager..."
    install_package "i3-wm"
    install_package "i3status"
    install_package "i3lock"
    install_package "dmenu"
    install_package "feh"
    install_package "picom"

    mkdir -p "$HOME/.config/i3"
    cat <<EOL > "$HOME/.config/i3/config"
# i3 Config File
set \$mod Mod4
bindsym \$mod+Return exec kitty
bindsym \$mod+d exec dmenu_run
bindsym \$mod+Shift+q kill
exec --no-startup-id feh --bg-scale ~/Pictures/wallpaper.jpg
exec --no-startup-id picom
EOL
    echo "i3 configuration complete."
}

# --------------------
# MAIN SCRIPT EXECUTION
# --------------------

main() {
    update_system
    install_aur_helper
    install_programs
    apply_dotfiles
    configure_i3
    echo "Setup complete! Please reboot to start using your system."
}

main

