#!/bin/bash
################################################################################
# Copyright (c) 2025 Hackerbot Industries LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Created By: Allen Chien
# Created:    April 2025
# Updated:    2025.04.01
#
# This script installs the Hackerbot software on a Raspberry Pi 5.
#
# Special thanks to the following for their code contributions to this codebase:
# Kyoung Whan Choe - https://github.com/kywch 


set -o pipefail

echo -e "###########################################################" 
echo -e "\e[1;37m #  #   ##    ###  #   #  ####  ### \e[1;32m  ###     #####  #####"
echo -e "\e[1;37m #  #  #  #  ##    #  #   #     #  #\e[1;32m  #  #   #    #    #"
echo -e "\e[1;37m ####  ####  #     ####   ####  ### \e[1;32m  ###   #     #    #"
echo -e "\e[1;37m #  #  #  #  ##    #  #   #     #  #\e[1;32m  #  #  #    #     #"
echo -e "\e[1;37m #  #  #  #   ###  #   #  ####  #  #\e[1;32m  ###   #####      #"
echo -e "\e[0m###########################################################"

echo "--------------------------------------------"
echo "STARTING HACKERBOT SOFTWARE INSTALL"
echo "--------------------------------------------"

check_raspberry_pi() {
    if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
        echo "System is Raspberry Pi 5."
    else
        echo "Warning: This script is designed for Raspberry Pi 5. Proceeding with caution."
    fi
}

check_raspberry_pi

handle_update_failure() {
    echo "ERROR: Failed to update system. Please check your network or permissions."
    cleanup
    exit 1
}

handle_install_failure() {
    echo "ERROR: Package installation failed. Please check your network or permissions."
    cleanup
    exit 1
}

cleanup() {
    echo "Cleaning up..."
    rm -rf "$HOME_DIR/hackerbot"
}

HOME_DIR="/home/$(whoami)"

# Prompt user for confirmation before proceeding
read -p "This script will remove the directory at $HOME_DIR/hackerbot and all of its contents. Do you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation canceled. Exiting."
    exit 1
fi

read -p "Do you want the virtual environment to activate automatically when you start a terminal (y/n)? " activate_venv
if [[ "$activate_venv" == "y" || "$activate_venv" == "Y" ]]; then
    VENV_CMD="source /home/$(whoami)/hackerbot/hackerbot_venv/bin/activate"
    if ! grep -Fxq "$VENV_CMD" ~/.bashrc; then
        echo "Adding virtual environment activation to .bashrc..."
        echo "$VENV_CMD" >> ~/.bashrc
        echo "Virtual environment will now activate automatically when starting a terminal."
    else
        echo "Virtual environment activation is already in .bashrc."
    fi
fi


# Remove existing directories before recreating them
cleanup

mkdir -p "$HOME_DIR/hackerbot"   # Directory for hackerbot workspace
mkdir -p "$HOME_DIR/hackerbot/logs" # Directory for logs
mkdir -p "$HOME_DIR/hackerbot/maps" # Directory for map data

LOG_FILE="$HOME_DIR/hackerbot_logs/setup_$(date +'%Y-%m-%d_%H-%M-%S').log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Updating and upgrading system..."
sudo apt-get update && sudo apt-get upgrade -y
if [ $? -ne 0 ]; then
    handle_update_failure
fi

echo "Installing required packages..."
sudo apt-get install -y python3 python3-pip git curl build-essential nodejs npm
if [ $? -ne 0 ]; then
    handle_install_failure
fi

echo "Creating virtual environment..."
python3 -m venv $HOME_DIR/hackerbot/hackerbot_venv
if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment."
    cleanup
    exit 1
fi
source $HOME_DIR/hackerbot/hackerbot_venv/bin/activate
echo "Virtual environment activated."

cd $HOME_DIR/hackerbot

echo "Cloning hackerbot lib..."
# git clone git@github.com:hackerbotindustries/hackerbot-lib.git # ssh
git clone https://github.com/hackerbotindustries/hackerbot-lib.git #HTTPS
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone hackerbot lib repository."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot/hackerbot-lib/hackerbot_modules/
echo "Installing hackerbot lib..."
pip install .
if [ $? -ne 0 ]; then
    echo "Error: Failed to install hackerbot lib."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot

echo "Cloning flask api..."
# git clone git@github.com:hackerbotindustries/hackerbot-flask-api.git # ssh
git clone https://github.com/hackerbotindustries/hackerbot-flask-api.git #HTTPS
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone flask api repository."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot

echo "Cloning command center..."
# git clone git@github.com:hackerbotindustries/hackerbot-command-center.git # ssh
git clone https://github.com/hackerbotindustries/hackerbot-command-center.git #HTTPS
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone flask api repository."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot/hackerbot-command-center/react/
echo "Installing frontend dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "Error: Failed to install frontend dependencies."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot/hackerbot-flask-api/
echo "Installing backend dependencies..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Error: Failed to install backend dependencies."
    cleanup
    exit 1
fi


# Function to add a line to crontab if not already present
add_to_cron() {
    local cmd="$1"
    (crontab -l 2>/dev/null | grep -v -F "$cmd"; echo "$cmd") | crontab -
}
echo "
--------------------------------------------
When starting FLASK API, and COMMAND CENTER at boot,
the script will occupy the serial port, and prevent other processes from using it.

To avoid this, you can run the script manually, and it will not occupy the serial port.
--------------------------------------------
Do you want the Flask API to run on startup? (y/n)
"
read -r flask_answer

echo "Do you want the Command Center to run on startup? (y/n)"
read -r command_center_answer

if [[ "$flask_answer" == "y"  || "$flask_answer" == "Y" ]]; then
    FLASK_CRON="@reboot bash -c 'source ~/hackerbot/hackerbot_venv/bin/activate && ./hackerbot/hackerbot-flask-api/launch_flask_api.sh' &"
    add_to_cron "$FLASK_CRON"
    echo "Flask API added to startup."
fi

if [[ "$command_center_answer" == "y" || "$command_center_answer" == "Y" ]]; then
    COMMAND_CENTER_CRON="@reboot bash -c './hackerbot/hackerbot-command-center/launch_command_center.sh' &"
    add_to_cron "$COMMAND_CENTER_CRON"
    echo "Command Center added to startup."
fi

echo "Setup completed successfully!"
