#!/bin/bash
set -e  # Exit on error

echo -e "###########################################################" 
echo -e "\e[1;37m #  #   ##    ###  #   #  ####  ### \e[1;32m  ###     #####  #####"
echo -e "\e[1;37m #  #  #  #  ##    #  #   #     #  #\e[1;32m  #  #   #    #    #"
echo -e "\e[1;37m ####  ####  #     ####   ####  ### \e[1;32m  ###   #     #    #"
echo -e "\e[1;37m #  #  #  #  ##    #  #   #     #  #\e[1;32m  #  #  #    #     #"
echo -e "\e[1;37m #  #  #  #   ###  #   #  ####  #  #\e[1;32m  ###   #####      #"
echo -e "\e[0m###########################################################"

echo "--------------------------------------------"
echo "CHECKING HACKERBOT SOFTWARE"
echo "--------------------------------------------"


# Check if running on Raspberry Pi 5
echo "
--CHECKING HARDWARE--
"
if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
    echo "System is a Raspberry Pi 5. ✅"
else
    echo "Warning: This script is designed for Raspberry Pi 5. Proceeding with caution. ❌"
fi

# List of required packages
REQUIRED_PACKAGES=("python3" "python3-pip" "git" "curl" "build-essential" "nodejs" "npm")
MISSING_PACKAGES=()

# Check if a package is installed with verbose output
echo "
--CHECKING APT PACKAGES--
"
for PACKAGE in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $PACKAGE "; then
        echo "$PACKAGE is NOT installed. ❌"
        MISSING_PACKAGES+=("$PACKAGE")
    fi
done


if [ ${#MISSING_APT_PACKAGES[@]} -ne 0 ]; then
    echo "Installing missing APT packages..."
    sudo apt-get update && sudo apt-get install -y "${MISSING_APT_PACKAGES[@]}"
else
    echo "All required APT packages are installed. ✅"
fi

# Check if virtual environment is activated
echo "
--CHECKING PYTHON VENV--
"
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "Warning: The 'hackerbot_venv' virtual environment is NOT activated! ❌"
    echo "Please activate it using: source hackerbot_venv/bin/activate"
    exit 1
else
    echo "Virtual environment is activated. ✅"
fi

# Define required pip packages
REQUIRED_PIP_PACKAGES=("blinker" "click" "Flask" "flask-cors" "hackerbot-helper" \
                        "itsdangerous" "Jinja2" "MarkupSafe" "pip" "pyserial" \
                        "python-dotenv" "setuptools" "Werkzeug")
MISSING_PIP_PACKAGES=()

# Check installed pip packages
echo "
--CHECKING PIP PACKAGES--
"
INSTALLED_PIP_PACKAGES=$(pip list --format=columns | awk '{print $1}' | tail -n +3)
for PIP_PACKAGE in "${REQUIRED_PIP_PACKAGES[@]}"; do
    if ! echo "$INSTALLED_PIP_PACKAGES" | grep -qw "$PIP_PACKAGE"; then
        echo "$PIP_PACKAGE is NOT installed. ❌"
        MISSING_PIP_PACKAGES+=("$PIP_PACKAGE")
    fi
done

# Notify about missing pip packages
if [ ${#MISSING_PIP_PACKAGES[@]} -ne 0 ]; then
    echo "Installing missing PIP packages..."
    pip install "${MISSING_PIP_PACKAGES[@]}"
else
    echo "All required PIP packages are installed. ✅"
fi
