#!/bin/bash
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
    rm -rf "$HOME_DIR/hackerbot_logs"
    rm -rf "$HOME_DIR/hackerbot_maps"
    rm -rf "$HOME_DIR/hackerbot_ws"
    rm -rf "$HOME_DIR/hackerbot_venv"
}

read -p "Do you want the virtual environment to activate automatically when you start a terminal (y/n)? " activate_venv
if [[ "$activate_venv" == "y" || "$activate_venv" == "Y" ]]; then
    VENV_CMD="source /home/$(whoami)/hackerbot_venv/bin/activate"
    if ! grep -Fxq "$VENV_CMD" ~/.bashrc; then
        echo "Adding virtual environment activation to .bashrc..."
        echo "$VENV_CMD" >> ~/.bashrc
        echo "Virtual environment will now activate automatically when starting a terminal."
    else
        echo "Virtual environment activation is already in .bashrc."
    fi
fi


HOME_DIR="/home/$(whoami)"

# Remove existing directories before recreating them
rm -rf "$HOME_DIR/hackerbot_logs"
rm -rf "$HOME_DIR/hackerbot_maps"
rm -rf "$HOME_DIR/hackerbot_ws"
rm -rf "$HOME_DIR/hackerbot_venv"

mkdir -p "$HOME_DIR/hackerbot_logs" # Directory for logs
mkdir -p "$HOME_DIR/hackerbot_maps" # Directory for map data
mkdir -p "$HOME_DIR/hackerbot_ws"   # Directory for hackerbot workspace

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
python3 -m venv $HOME_DIR/hackerbot_venv
if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment."
    cleanup
    exit 1
fi
source $HOME_DIR/hackerbot_venv/bin/activate
echo "Virtual environment activated."

cd $HOME_DIR/hackerbot_ws

echo "Cloning hackerbot lib..."
git clone git@github.com:AllenChienXXX/hackerbot_lib.git
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone hackerbot lib repository."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot_ws/hackerbot_lib/hackerbot_modules/
echo "Installing hackerbot lib..."
pip install .
if [ $? -ne 0 ]; then
    echo "Error: Failed to install hackerbot lib."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot_ws

echo "Cloning web app..."
git clone git@github.com:AllenChienXXX/hackerbot_web.git
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone web app repository."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot_ws/hackerbot_web/hackerbot_command_center/
echo "Installing frontend dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "Error: Failed to install frontend dependencies."
    cleanup
    exit 1
fi

cd $HOME_DIR/hackerbot_ws/hackerbot_web/hackerbot_flask_api/
echo "Installing backend dependencies..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Error: Failed to install backend dependencies."
    cleanup
    exit 1
fi

echo "Setup completed successfully!"
