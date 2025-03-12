#!/bin/bash
set -o pipefail

sudo echo "--------------------------------------------"
echo "STARTING HACKERBOT SOFTWARE INSTALL"
echo "--------------------------------------------"

# Function to check if the system is Raspberry Pi 5
check_raspberry_pi() {
    if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
        echo "System is Raspberry Pi 5."
    else
        echo "Warning: This script is designed for Raspberry Pi 5. Proceeding with caution."
    fi
}

# Function to handle apt update failure
handle_update_failure() {
    echo "Error: Failed to update system. Please check your network, system permissions or contact Hackerbot Support."
    exit 1
}

# Ask user if they want the virtual environment to activate on terminal start
read -p "Do you want the virtual environment to activate automatically when you start a terminal (y/n)? " activate_venv
if [[ "$activate_venv" == "y" || "$activate_venv" == "Y" ]]; then
    echo "Adding virtual environment activation to .bashrc..."
    echo "source /root/venv/bin/activate" >> ~/.bashrc
    echo "Virtual environment will now activate automatically when starting a terminal."
fi

# Ask user if they want software to be updated every time the robot starts
# read -p "Do you want the software to be updated automatically every time the robot starts (y/n)? " auto_update
# if [[ "$auto_update" == "y" || "$auto_update" == "Y" ]]; then
#     echo "Adding software update command to startup script..."
#     echo "sudo apt-get update && sudo apt-get upgrade -y" >> ~/.bashrc
#     echo "Software will now be updated automatically when the robot starts."
# fi

# Update and upgrade apt, and install necessary packages
echo "Updating and upgrading system..."
sudo apt-get update && sudo apt-get upgrade -y
if [ $? -ne 0 ]; then
    handle_update_failure
fi

echo "Installing required packages..."
sudo apt-get install -y python3 python3-pip git curl build-essential

# Step 1: Create and activate virtual environment
echo "Creating virtual environment..."
python3 -m venv /root/hackerbot_venv
source /root/hackerbot_venv/bin/activate
echo "Virtual environment activated."

# Step 2: Clone and install hackerbot workspace
echo "Cloning hackerbot workspace..."
git clone git@github.com:AllenChienXXX/hackerbot_ws.git 
cd hackerbot_ws/hackerbot_modules/
echo "Installing hackerbot workspace..."
pip install .

# Step 3: Clone web app and install dependencies
echo "Cloning web app..."
git clone git@github.com:AllenChienXXX/map_UI.git
cd map_UI/
cd hackerbot-dashboard/
echo "Installing frontend dependencies..."
npm install

# Install backend dependencies
cd ../flask_app/
echo "Installing backend dependencies..."
pip install -r requirements.txt

# Final message
echo "Setup completed successfully!"
