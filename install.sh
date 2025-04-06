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
# Allen Chien - https://github.com/AllenChienXXX
# Ian Bernstein - https://github.com/arobodude
################################################################################


set -o pipefail

echo -e "###########################################################" 
echo -e "\e[1;37m #  #   ##    ###  #   #  ####  ### \e[1;32m  ###     #####  #####"
echo -e "\e[1;37m #  #  #  #  ##    #  #   #     #  #\e[1;32m  #  #   #    #    #"
echo -e "\e[1;37m ####  ####  #     ####   ####  ### \e[1;32m  ###   #     #    #"
echo -e "\e[1;37m #  #  #  #  ##    #  #   #     #  #\e[1;32m  #  #  #    #     #"
echo -e "\e[1;37m #  #  #  #   ###  #   #  ####  #  #\e[1;32m  ###   #####      #"
echo -e "\e[0m###########################################################"

echo "--------------------------------------------"
echo "STARTING HACKERBOT SOFTWARE INSTALLER"
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

echo "This installation script will take a few minutes to complete."
read -p "Do you wish to continue? (y/n): " proceed
if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
    echo "Installation aborted by user."
    exit 1
fi

if [ -d "$HOME_DIR/hackerbot" ]; then
    echo "WARNING: The directory $HOME_DIR/hackerbot already exists. It will be removed and replaced."
    read -p "Do you wish to continue? (y/n): " dir_confirm
    if [[ "$dir_confirm" != "y" && "$dir_confirm" != "Y" ]]; then
        echo "Operation canceled. Exiting."
        exit 1
    fi
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

LOG_FILE="$HOME_DIR/hackerbot/logs/setup_$(date +'%Y-%m-%d_%H-%M-%S').log"

echo "Logs will be saved to: $LOG_FILE"

echo "Updating and upgrading system..."
{ 
    sudo apt-get update && sudo apt-get upgrade -y
} >> "$LOG_FILE" 2>&1 || handle_update_failure

echo "Installing required packages..."
{
    sudo apt-get install -y python3 python3-pip git curl build-essential nodejs npm
} >> "$LOG_FILE" 2>&1 || handle_install_failure

echo "Creating python virtual environment..."
python3 -m venv $HOME_DIR/hackerbot/hackerbot_venv
if [ $? -ne 0 ]; then
    echo "Error: Failed to create python virtual environment."
    cleanup
    exit 1
fi

source $HOME_DIR/hackerbot/hackerbot_venv/bin/activate
echo "Python virtual environment activated."

cd $HOME_DIR/hackerbot

echo "Cloning hackerbot python package..."
git clone https://github.com/hackerbotindustries/hackerbot-python-package.git >> "$LOG_FILE" 2>&1 || {
    echo "ERROR: Failed to clone hackerbot-python-package. See $LOG_FILE"
    cleanup
    exit 1
}

# cd "$HOME_DIR/hackerbot/hackerbot-python-package/hackerbot_modules/"
# echo "Installing hackerbot python package..."
# pip install . >> "$LOG_FILE" 2>&1 || {
#     echo "Error: Failed to install hackerbot python package. See $LOG_FILE"
#     cleanup
#     exit 1
# }

cd $HOME_DIR/hackerbot

echo "Cloning hackerbot-flask-api..."
git clone https://github.com/hackerbotindustries/hackerbot-flask-api.git >> "$LOG_FILE" 2>&1 || {
    echo "ERROR: Failed to clone hackerbot-flask-api. See $LOG_FILE"
    cleanup
    exit 1
}

cd $HOME_DIR/hackerbot

echo "Cloning hackerbot-command-center..."
git clone https://github.com/hackerbotindustries/hackerbot-command-center.git >> "$LOG_FILE" 2>&1 || {
    echo "ERROR: Failed to clone hackerbot-command-center. See $LOG_FILE"
    cleanup
    exit 1
}

cd $HOME_DIR/hackerbot/hackerbot-command-center/react/
{
    npm install
} >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to install react dependencies."
    cleanup
    exit 1
}

cd $HOME_DIR/hackerbot/hackerbot-flask-api/
echo "Installing backend dependencies..."
{
    pip install -r requirements.txt
} >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to install backend dependencies."
    cleanup
    exit 1
}

# Function to add a line to crontab if not already present
add_to_cron() {
    local cmd="$1"
    (crontab -l 2>/dev/null | grep -v -F "$cmd"; echo "$cmd") | crontab -
}

cat <<EOF
--------------------------------------------
When starting FLASK API, and COMMAND CENTER at boot,
the script will occupy the serial port, and prevent other processes from using it.

To avoid this, you can run the script manually, and it will not occupy the serial port.
--------------------------------------------
Do you want the Flask API to run on startup? (y/n)
EOF
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
