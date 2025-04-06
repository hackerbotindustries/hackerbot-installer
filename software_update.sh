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
# This script checks for updates to the Hackerbot software on a Raspberry Pi 5.
################################################################################

set -euo pipefail  # Strict mode

echo "--------------------------------------------"
echo "CHECKING HACKERBOT SOFTWARE"
echo "--------------------------------------------"

HOME_DIR="/home/$(whoami)"
LOG_DIR="$HOME_DIR/hackerbot/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update_$(date +'%Y-%m-%d_%H-%M-%S').log"

# Check if running on Raspberry Pi 5
echo "
--CHECKING HARDWARE--
"
if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
    echo "System is a Raspberry Pi 5. ✅"
else
    echo "Warning: This script is designed for Raspberry Pi 5. Proceeding with caution. ❌"
fi

# Begin transaction block
(
    echo "
--CHECKING APT PACKAGES--
    "
    REQUIRED_APT_PACKAGES=("python3" "python3-pip" "git" "curl" "build-essential" "nodejs" "npm")
    MISSING_APT_PACKAGES=()
    for PACKAGE in "${REQUIRED_APT_PACKAGES[@]}"; do
        if ! dpkg -s "$PACKAGE" &>/dev/null; then
            echo "$PACKAGE is NOT installed. ❌"
            MISSING_APT_PACKAGES+=("$PACKAGE")
        fi
    done

    if [ ${#MISSING_APT_PACKAGES[@]} -ne 0 ]; then
        echo "Missing packages: ${MISSING_APT_PACKAGES[*]}"
        echo "Installing missing APT packages..."
        sudo apt-get update >> "$LOG_FILE" 2>&1
        sudo apt-get install -y "${MISSING_APT_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
    else
        echo "All required APT packages are installed. ✅"
    fi

    echo "
--CHECKING PYTHON VENV--
    "
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "Error: 'hackerbot_venv' virtual environment is NOT activated! ❌"
        echo "Please activate it using: source hackerbot_venv/bin/activate"
        exit 1
    else
        echo "Virtual environment is activated. ✅"
    fi

    echo "
--CHECKING PIP PACKAGES--
    "
    REQUIRED_PIP_PACKAGES=("blinker" "click" "Flask" "flask-cors" # "hackerbot-helper"
                            "itsdangerous" "Jinja2" "MarkupSafe" "pip" "pyserial" \
                            "python-dotenv" "setuptools" "Werkzeug")
    MISSING_PIP_PACKAGES=()
    INSTALLED_PIP_PACKAGES=$(pip list --format=columns | awk '{print $1}' | tail -n +3)

    for PIP_PACKAGE in "${REQUIRED_PIP_PACKAGES[@]}"; do
        if ! echo "$INSTALLED_PIP_PACKAGES" | grep -qw "$PIP_PACKAGE"; then
            echo "$PIP_PACKAGE is NOT installed. ❌"
            MISSING_PIP_PACKAGES+=("$PIP_PACKAGE")
        fi
    done

    if [ ${#MISSING_PIP_PACKAGES[@]} -ne 0 ]; then
        echo "Installing missing PIP packages..."
        pip install "${MISSING_PIP_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
    else
        echo "All required PIP packages are installed. ✅"
    fi
) || {
    echo -e "\n❌ Error occurred during update process. Check log at: $LOG_FILE"
    exit 1
}

echo -e "\n✅ Update check and installation completed successfully."
echo "Log saved at: $LOG_FILE"
