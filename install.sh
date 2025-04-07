#!/bin/bash
################################################################################
# Copyright (c) 2025 Hackerbot Industries LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Created By: Allen Chien
# Created:    April 2025
# Updated:    2025.04.06
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
mkdir -p "$HOME_DIR/hackerbot" "$HOME_DIR/hackerbot/logs" "$HOME_DIR/hackerbot/maps"

LOG_FILE="$HOME_DIR/hackerbot/logs/setup_$(date +'%Y-%m-%d_%H-%M-%S').log"

# System Update
echo "[STEP] Updating system..."
sudo apt-get update >> "$LOG_FILE" 2>&1 || handle_update_failure
sudo apt-get upgrade -y >> "$LOG_FILE" 2>&1 || handle_update_failure

# Package Installation
echo "[STEP] Installing required packages..."
sudo apt-get install -y python3 python3-pip git curl build-essential nodejs npm bats >> "$LOG_FILE" 2>&1 || handle_install_failure

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

# Clone Repositories
cd "$HOME_DIR/hackerbot"
for repo in hackerbot-python-package hackerbot-flask-api hackerbot-command-center; do
    echo "[STEP] Cloning $repo..."
    git clone https://github.com/hackerbotindustries/$repo.git >> "$LOG_FILE" 2>&1 || {
        echo "[ERROR] Failed to clone $repo. See log: $LOG_FILE"
        cleanup
        exit 1
    }
    echo "[OK] Cloned $repo."
done

# Install Python Package
cd "$HOME_DIR/hackerbot/hackerbot-python-package/hackerbot_modules/"
echo "[STEP] Installing Hackerbot Python package..."
pip install . >> "$LOG_FILE" 2>&1 || {
    echo "[ERROR] Failed to install Hackerbot Python package. See $LOG_FILE"
    cleanup
    exit 1
}
echo "[OK] Hackerbot Python package installed."
echo

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

# Completion Message
cd "$HOME_DIR/hackerbot-installer"
echo -e "============================================================="
echo "SETUP COMPLETE"
echo -e "============================================================="
echo "Install logs saved to: $LOG_FILE"
echo

echo "Command Center:"
echo "  Launch: cd ~/hackerbot/hackerbot-command-center/ && ./launch_command_center.sh"
echo "  Stop:   cd ~/hackerbot/hackerbot-command-center/ && ./stop_command_center.sh"
echo

echo "Flask API:"
echo "  Launch: cd ~/hackerbot/hackerbot-flask-api/ && ./launch_flask_api.sh"
echo "  Stop:   cd ~/hackerbot/hackerbot-flask-api/ && ./stop_flask_api.sh"
echo
