#!/bin/bash

# Configurable delay between installations
DELAY=1  # Delay in seconds

# Function to check if a package is installed
is_installed() {
    pacman -Q "$1" &> /dev/null
}


# Function to handle PGP signature issues and refresh the keyring
refresh_keyring_and_update() {
    echo -e "\n\e[1;33mRefreshing keyring and updating the system...\e[0m"

    # Update keyring before system update
    sudo pacman -Sy --noconfirm archlinux-keyring
    sudo pacman-key --init
    sudo pacman-key --populate archlinux

    echo -e "\e[1;34mRefreshing keys (this may take a moment)...\e[0m"
    
    # Set a timeout for key refresh to prevent long hangs
    if ! timeout 5 sudo pacman-key --refresh-keys; then
        echo -e "\e[1;31mKey refresh timed out or failed.\e[0m"
    fi

    # Proceed with full system update
    sudo pacman -Syu --noconfirm

    echo -e "\e[1;32mSystem refresh completed successfully!\e[0m"
    echo -e "\n###########################################\n"
    sleep $DELAY
}

# Function to update the system and handle errors
update_system() {
    echo -e "\n\e[1;34mUpdating the system...\e[0m"

    if ! sudo pacman -Syu --noconfirm; then
        echo -e "\e[1;31mError during system update. Attempting to resolve PGP signature issues...\e[0m"
        refresh_keyring_and_update
    else
        echo -e "\e[1;32mSystem update completed successfully!\e[0m"
    fi

    echo -e "\n###########################################\n"
    sleep $DELAY
}

# Function to install a package using pacman
install_package() {
    local package="$1"
    if ! is_installed "$package"; then
        echo -e "\e[1;34mInstalling $package...\e[0m"
        if ! sudo pacman -S --noconfirm "$package"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to install $package" >> failed_packages.log
        fi
        
    else
        echo -e "\e[1;32m$package is already installed. Skipping.\e[0m"
        echo -e "\n\n###########################################\n\n"
    fi
    sleep $DELAY
}

# Function to install AUR packages using yay
install_aur_package() {
    local package="$1"
    if ! is_installed "$package"; then
        echo -e "\e[1;34mInstalling $package from AUR...\e[0m"
        if ! yay -S --noconfirm "$package"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to install $package" >> failed_packages.log
        fi
        
    else
        echo -e "\e[1;32m$package is already installed. Skipping.\e[0m"
        echo -e "\n\n###########################################\n\n"
    fi
    sleep $DELAY
}

# Function to handle Conda installations
install_conda_tools() {
    if command -v conda &> /dev/null; then
        echo -e "\e[1;34mAnaconda is installed. Updating and managing dependencies...\e[0m"
        conda update -y conda
        conda install -y -c conda-forge pandoc
        conda update -y --all
        conda clean -y --all
        echo -e "\e[1;32mAnaconda-related operations completed.\e[0m"
        echo -e "\n###########################################\n"
    else
        echo -e "\e[1;31mAnaconda is not installed. Please install it manually.\e[0m"
        echo -e "\n###########################################\n"
    fi
    sleep $DELAY
}

# Function to install and configure printer support
configure_printer() {
    if grep -q "workgroup = WORKGROUP" /etc/samba/smb.conf; then
        echo -e "\e[1;32mPrinter configuration already exists. Skipping.\e[0m"
    else
        echo -e "\e[1;34mConfiguring printer...\e[0m"
        echo -e "\n[global]\nworkgroup = WORKGROUP\nsecurity = user\nclient min protocol = SMB2\nclient max protocol = SMB3" | sudo tee -a /etc/samba/smb.conf
        echo -e "\e[1;32mPrinter configuration completed successfully!\e[0m"
    fi
    echo -e "\n###########################################\n"
    sleep $DELAY
}


# Function to remove orphaned dependencies
remove_orphans() {
    if sudo pacman -Qtdq &>/dev/null; then
        echo -e "\e[1;34mRemoving orphaned dependencies...\e[0m"
        sudo pacman -Rns $(pacman -Qtdq) --noconfirm
    else
        echo -e "\e[1;32mNo orphaned dependencies found.\e[0m"
    fi
}

# Function to change the Grub theme
grub_theme_change() {

    # Grub2 Theme

    ROOT_UID=0
    THEME_DIR="/usr/share/grub/themes"
    THEME_NAME=Stylish

    MAX_DELAY=20                                        # max delay for user to enter root password

    #COLORS
    CDEF=" \033[0m"                                     # default color
    CCIN=" \033[0;36m"                                  # info color
    CGSC=" \033[0;32m"                                  # success color
    CRER=" \033[0;31m"                                  # error color
    CWAR=" \033[0;33m"                                  # waring color
    b_CDEF=" \033[1;37m"                                # bold default color
    b_CCIN=" \033[1;36m"                                # bold info color
    b_CGSC=" \033[1;32m"                                # bold success color
    b_CRER=" \033[1;31m"                                # bold error color
    b_CWAR=" \033[1;33m"                                # bold warning color

    # echo like ...  with  flag type  and display message  colors
    prompt () {
    case ${1} in
        "-s"|"--success")
        echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
        "-e"|"--error")
        echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
        "-w"|"--warning")
        echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
        "-i"|"--info")
        echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
        *)
        echo -e "$@"
        ;;
    esac
    }

    # Welcome message
    prompt -s "\n\t***************************\n\t*  ${THEME_NAME} - Grub2 Theme  *\n\t***************************"

    # Check command avalibility
    function has_command() {
    command -v $1 > /dev/null
    }

    prompt -w "\nChecking for root access...\n"

    # Checking for root access and proceed if it is present
    if [ "$UID" -eq "$ROOT_UID" ]; then

    # Create themes directory if not exists
    prompt -i "\nChecking for the existence of themes directory...\n"
    [[ -d ${THEME_DIR}/${THEME_NAME} ]] && rm -rf ${THEME_DIR}/${THEME_NAME}
    mkdir -p "${THEME_DIR}/${THEME_NAME}"

    # Copy theme
    prompt -i "\nInstalling ${THEME_NAME} theme...\n"

    cp -a ${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}

    # Set theme
    prompt -i "\nSetting ${THEME_NAME} as default...\n"

    # Backup grub config
    cp -an /etc/default/grub /etc/default/grub.bak

    grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub

    echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub

    # Update grub config
    echo -e "Updating grub config..."
    if has_command update-grub; then
        update-grub
    elif has_command grub-mkconfig; then
        grub-mkconfig -o /boot/grub/grub.cfg
    elif has_command grub2-mkconfig; then
        if has_command zypper; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        elif has_command dnf; then
        grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
        fi
    fi

    # Success message
    prompt -s "\n\t          ***************\n\t          *  All done!  *\n\t          ***************\n"

    else

    # Error message
    prompt -e "\n [ Error! ] -> Run me as root "

    # persisted execution of the script as root
    read -p "[ trusted ] specify the root password : " -t${MAX_DELAY} -s
    [[ -n "$REPLY" ]] && {
        sudo -S <<< $REPLY $0
    } || {
        prompt  "\n Operation canceled  Bye"
        exit 1
    }
    fi

}

# Function to install yay AUR helper
install_yay() {
    echo -e "\n\e[1;34mInstalling yay AUR helper...\e[0m"

    # Install necessary dependencies
    sudo pacman -S --needed --noconfirm git base-devel

    # Clone the yay-bin repository
    if [[ -d "$HOME/yay-bin" ]]; then
        echo -e "\e[1;33mRemoving existing yay-bin directory...\e[0m"
        rm -rf "$HOME/yay-bin"
    fi

    git clone https://aur.archlinux.org/yay-bin.git "$HOME/yay-bin"

    # Build and install yay
    cd "$HOME/yay-bin" || exit 1
    makepkg -si --noconfirm

    # Clean up
    cd "$HOME" && rm -rf "$HOME/yay-bin"

    # Verify installation
    if command -v yay &>/dev/null; then
        echo -e "\e[1;32mYay installed successfully!\e[0m"
    else
        echo -e "\e[1;31mYay installation failed.\e[0m"
    fi
}

# Function to install all tools and apps
install_all_tools() {
    echo -e "\e[1;34mInstalling all essential tools and applications...\e[0m"
    update_system

    # Install yay
    install_package "fakeroot"
    install_yay

    # Install AUR packages
    install_aur_package "google-chrome"
    install_aur_package "visual-studio-code-bin"
    install_aur_package "slack-desktop"
    install_aur_package "spotify"
    install_aur_package "localsend-bin"
    # install_aur_package "discord"

    # Install essential development tools
    install_package "gnome-disk-utility"
    install_package "gdb"
    install_package "tree"
    install_package "qbittorrent"
    install_package "net-tools"
    install_package "noto-fonts-emoji"
    install_package "openssh"
    install_package "neofetch"
    install_package "vim"
    install_package "vlc"
    install_package "hugo"
    install_package "tmux"
    install_package "jdk-openjdk"
    install_package "python"
    install_package "python-virtualenv"
    install_package "python-pip"
    install_package "texlive"
    install_package "texstudio"
    install_package "cmatrix"
    install_package "fortune-mod"
    install_package "cowsay"
    install_package "linux-headers"
    install_package "ntfs-3g"
    install_package "exfatprogs"
    # install_package "xournalpp"

    # Configure printer support
    configure_printer

    # Change Grub Theme
    grub_theme_change

    # Install Conda tools
    install_conda_tools

    # Remove orphaned dependencies
    remove_orphans

    # Clean package cache
    sudo pacman -Sc --noconfirm

    echo -e "\e[1;32mAll tools and applications installed successfully!\e[0m"
    echo -e "\n###########################################\n"
}

# Function to display a theme and style
display_theme() {
    echo -e "\e[1;35m###############################\e[0m"
    echo -e "\e[1;35m Welcome to the Arch Setup \e[0m"
    echo -e "\e[1;35m###############################\e[0m"
}

# Main function to handle script execution
main() {
    clear
    display_theme

    echo -e "\n\e[1;32m1. Install All Tools\e[0m"
    echo -e "\e[1;32m0. Exit\e[0m"

    read -p "Enter your choice: " choice

    case $choice in
        1)
            install_all_tools
            ;;
        0)
            echo -e "\e[1;36mGoodbye!\e[0m"
            exit 0
            ;;
        *)
            echo -e "\e[1;31mInvalid option, please try again.\e[0m"
            ;;
    esac

    read -p "Do you want to continue? (y/n): " continue_choice
    if [[ "$continue_choice" != "y" ]]; then
        echo -e "\e[1;36mGoodbye!\e[0m"
        exit 0
    else
        main
    fi
}

# Run the main function
main

