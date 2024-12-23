#!/bin/bash

# This script automates the installation and configuration of an Arch Linux system
# tailored to user preferences. It installs specified tools, themes, and fonts,
# and configures the i3 window manager with a highly customized setup.

# --------------------
# HELPER FUNCTIONS
# --------------------

# Function to check if a package is installed
is_installed() {
    pacman -Q "$1" &> /dev/null
}

# Function to install a package
install_package() {
    local package="$1"
    if ! is_installed "$package"; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm "$package"
    else
        echo "$package is already installed. Skipping."
    fi
}

# Function to install an AUR package using yay
install_aur_package() {
    local package="$1"
    if ! is_installed "$package"; then
        echo "Installing $package from AUR..."
        yay -S --noconfirm "$package"
    else
        echo "$package is already installed. Skipping."
    fi
}

# --------------------
# SYSTEM UPDATE & TOOLS
# --------------------

# Update system and install essential tools
update_system() {
    echo "Updating system..."
    sudo pacman -Syu --noconfirm

    echo "Installing essential tools..."
    install_package "base-devel"
    install_package "git"
    install_package "curl"
    install_package "wget"
    install_package "htop"
}

# Install AUR helper (yay)
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay (AUR helper)..."
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit
        makepkg -si --noconfirm
        cd .. && rm -rf yay
    else
        echo "yay is already installed. Skipping."
    fi
}

# --------------------
# INSTALL APPLICATIONS
# --------------------

install_applications() {
    echo "Installing applications..."

    # File Manager
    install_package "nemo"

    # Terminal Emulator
    install_package "kitty"

    # RSS Reader
    install_package "newsboat"

    # Music & Video Player
    install_package "vlc"

    # Web Browser
    install_aur_package "google-chrome"

    # Text Editors
    install_package "vim"
    install_package "nano"
    install_aur_package "visual-studio-code-bin"

    # Fonts and Themes
    install_package "ttf-nerd-fonts-symbols-common"
    install_aur_package "nordic-theme"

    echo "Applications installed successfully."
}

# --------------------
# CONFIGURE i3 WINDOW MANAGER
# --------------------

configure_i3() {
    echo "Installing and configuring i3..."

    # Install i3 and dependencies
    install_package "i3-wm"
    install_package "i3status"
    install_package "i3lock"
    install_package "dmenu"
    install_package "feh"       # For setting wallpapers
    install_package "picom"     # For compositing (transparency, shadows, etc.)

    # Create configuration directories
    mkdir -p "$HOME/.config/i3"

    # Download and apply a highly customized i3 config
    echo "Creating i3 configuration..."

    cat <<EOL > $HOME/.config/i3/config
# i3 Configuration File
# -----------------------

# Set mod key to Mod4 (Super/Windows key)
set \$mod Mod4

# Basic keybindings
bindsym \$mod+Return exec kitty  # Open Kitty terminal
bindsym \$mod+d exec dmenu_run  # Open dmenu
bindsym \$mod+Shift+q kill      # Kill focused window
bindsym \$mod+Shift+r restart   # Restart i3
bindsym \$mod+Shift+e exec --no-startup-id "i3-msg exit"  # Exit i3

# Workspaces
set \$ws1 "1: Browser"
set \$ws2 "2: Code"
set \$ws3 "3: Terminal"

workspace \$ws1 output HDMI-1
workspace \$ws2 output HDMI-1
workspace \$ws3 output HDMI-1

# Appearance
font pango:Nerd Font 10
exec_always --no-startup-id picom --config ~/.config/picom.conf

# Wallpaper
exec_always --no-startup-id feh --bg-scale ~/Pictures/wallpaper.jpg
EOL

    echo "i3 configured successfully."
}

# --------------------
# MAIN SCRIPT EXECUTION
# --------------------

main() {
    update_system
    install_yay
    install_applications
    configure_i3

    echo "Setup complete! Please log out and log back in to use i3."
}

main

