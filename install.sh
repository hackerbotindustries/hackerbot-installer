#!/bin/bash
################################################################################
# Copyright (c) 2025 Hackerbot Industries LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Created By: Allen Chien
# Created:    April 2025
# Updated:    2025.04.16
#
# This script installs the Hackerbot software on a Raspberry Pi 5.
# Run ". install.sh or source install.sh" if you wish to activate venv right away.
#
# Special thanks to the following for their code contributions to this codebase:
# Allen Chien - https://github.com/AllenChienXXX
################################################################################


set -o pipefail

clear
echo -e "=============================================================" 
echo -e " HACKERBOT SOFTWARE INSTALLER"
echo -e "============================================================="
echo

# System Check
check_raspberry_pi() {
    echo -e "[INFO] Detecting system type..."
    if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
        echo "[OK] System is Raspberry Pi 5."
    else
        echo "[WARNING] This script is designed for Raspberry Pi 5. Proceeding with caution."
    fi
    echo
}

check_raspberry_pi

# Failure Handlers
handle_update_failure() {
    echo "[ERROR] Failed to update system. Please check your network or permissions."
    cleanup
    exit 1
}

handle_install_failure() {
    echo "[ERROR] Package installation failed. Please check your network or permissions."
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    echo "[INFO] Cleaning up existing installation..."
    rm -rf "$HOME_DIR/hackerbot"
    rm -rf "~/.local/bin"
    echo
}

HOME_DIR="/home/$(whoami)"
echo "This installation may take a few minutes."
read -p "Do you want to continue? (y/n): " proceed
if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
    echo "[INFO] Installation aborted by user."
    exit 0
fi

# Confirm overwrite
if [ -d "$HOME_DIR/hackerbot" ]; then
    echo "[WARNING] Directory $HOME_DIR/hackerbot already exists and will be removed."
    read -p "Do you want to continue? (y/n): " dir_confirm
    if [[ "$dir_confirm" != "y" && "$dir_confirm" != "Y" ]]; then
        echo "[INFO] Operation canceled. Exiting."
        exit 0
    fi
fi

# Auto-activate virtual env option
read -p "Auto-activate virtual environment on terminal startup? (y/n): " activate_venv
if [[ "$activate_venv" == "y" || "$activate_venv" == "Y" ]]; then
    VENV_CMD="source /home/$(whoami)/hackerbot/hackerbot_venv/bin/activate"
    if ! grep -Fxq "$VENV_CMD" ~/.bashrc; then
        echo "[INFO] Adding virtual environment activation to .bashrc..."
        echo "$VENV_CMD" >> ~/.bashrc
        echo "[INFO] Auto-activation added."
    else
        echo "[INFO] Auto-activation already present in .bashrc."
    fi
    echo
fi

# Cleanup and Directory Setup
cleanup
mkdir -p "$HOME_DIR/hackerbot" "$HOME_DIR/hackerbot-installer/logs"

LOG_FILE="$HOME_DIR/hackerbot-installer/logs/setup_$(date +'%Y-%m-%d_%H-%M-%S').log"

# System Update
echo "[STEP] Updating system..."
sudo apt-get update >> "$LOG_FILE" 2>&1 || handle_update_failure
sudo apt-get upgrade -y >> "$LOG_FILE" 2>&1 || handle_update_failure

# Package Installation
echo "[STEP] Installing required packages..."
sudo apt-get install -y python3 python3-pip python3.11-venv git curl build-essential nodejs npm bats portaudio19-dev cmake libgtk-3-dev >> "$LOG_FILE" 2>&1 || handle_install_failure

# Python Environment
echo "[STEP] Creating Python virtual environment..."
python3 -m venv "$HOME_DIR/hackerbot/hackerbot_venv" || {
    echo "[ERROR] Failed to create virtual environment."
    cleanup
    exit 1
}
source "$HOME_DIR/hackerbot/hackerbot_venv/bin/activate"
echo "[OK] Virtual environment activated."
echo

# Install Required Python Packages with Specified Versions
declare -A REQUIRED_PIP_PACKAGES=(
    [blinker]="1.9.0"
    [click]="8.1.8"
    [Flask]="3.1.0"
    [flask-cors]="5.0.1"
    [iniconfig]="2.1.0"
    [itsdangerous]="2.2.0"
    [Jinja2]="3.1.5"
    [MarkupSafe]="3.0.2"
    [packaging]="24.2"
    [pip]="23.0.1"
    [pluggy]="1.5.0"
    [pyserial]="3.5"
    [pytest]="8.3.5"
    [python-dotenv]="1.0.1"
    [setuptools]="66.1.1"
    [Werkzeug]="3.1.3"
    [hackerbot]=""
)

echo "[STEP] Installing required pip packages with specific versions..."
for pkg in "${!REQUIRED_PIP_PACKAGES[@]}"; do
    version="${REQUIRED_PIP_PACKAGES[$pkg]}"
    if [ -z "$version" ]; then
        # echo "[INFO] Installing latest version of $pkg..."
        pip install --upgrade "$pkg" >> "$LOG_FILE" 2>&1 || {
            echo "[ERROR] Failed to install latest $pkg. See log: $LOG_FILE"
            cleanup
            exit 1
        }
    else
        # echo "[INFO] Installing $pkg==$version..."
        pip install "$pkg==$version" >> "$LOG_FILE" 2>&1 || {
            echo "[ERROR] Failed to install $pkg==$version. See log: $LOG_FILE"
            cleanup
            exit 1
        }
    fi
done
echo "[OK] All pip packages installed."

# Clone Repositories
cd "$HOME_DIR/hackerbot"
for repo in hackerbot-python-package hackerbot-flask-api hackerbot-command-center hackerbot-tutorials; do
    echo "[STEP] Cloning $repo..."
    git clone https://github.com/hackerbotindustries/$repo.git >> "$LOG_FILE" 2>&1 || {
        echo "[ERROR] Failed to clone $repo. See log: $LOG_FILE"
        cleanup
        exit 1
    }
    echo "[OK] Cloned $repo."
done

# Install Dependencies
cd "$HOME_DIR/hackerbot/hackerbot-command-center/react/"
echo "[STEP] Installing React dependencies..."
npm install >> "$LOG_FILE" 2>&1 || {
    echo "[ERROR] Failed to install React dependencies."
    cleanup
    exit 1
}
echo "[OK] React dependencies installed."

echo "[STEP] Installing Flask dependencies..."
cd "$HOME_DIR/hackerbot/hackerbot-flask-api/"
pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || {
    echo "[ERROR] Failed to install Flask dependencies."
    cleanup
    exit 1
}
echo "[OK] Flask dependencies installed."
echo

echo "[STEP] Setting up global scripts..."

mkdir -p ~/.local/bin || {
    echo "[ERROR] Failed to create ~/.local/bin."
    cleanup
    exit 1
}

ln -sf "$HOME/hackerbot/hackerbot-command-center/launch_command_center.sh" ~/.local/bin/launch-command-center || {
    echo "[ERROR] Failed to symlink launch_command_center.sh."
    cleanup
    exit 1
}

ln -sf "$HOME/hackerbot/hackerbot-command-center/stop_command_center.sh" ~/.local/bin/stop-command-center || {
    echo "[ERROR] Failed to symlink stop_command_center.sh."
    cleanup
    exit 1
}

ln -sf "$HOME/hackerbot/hackerbot-flask-api/launch_flask_api.sh" ~/.local/bin/launch-flask-api || {
    echo "[ERROR] Failed to symlink launch_flask_api.sh."
    cleanup
    exit 1
}

ln -sf "$HOME/hackerbot/hackerbot-flask-api/stop_flask_api.sh" ~/.local/bin/stop-flask-api || {
    echo "[ERROR] Failed to symlink stop_flask_api.sh."
    cleanup
    exit 1
}

# Add ~/.local/bin to PATH in .bashrc if not already there
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc || {
        echo "[ERROR] Failed to append to .bashrc."
        cleanup
        exit 1
    }
    echo "[+] Added ~/.local/bin to your PATH in ~/.bashrc"
fi

echo "[OK] Global scripts configured."
echo

# Completion Message
cd "$HOME_DIR/hackerbot-installer"
echo -e "============================================================="
echo "SETUP COMPLETE"
echo -e "============================================================="
echo "Install logs saved to: $LOG_FILE"
echo

echo "Startup Configuration:"
echo "  If you wish to configure the Flask API or Command Center"
echo "  to start automatically on system boot, run:"
echo
echo "    source boot_configure.sh"
echo