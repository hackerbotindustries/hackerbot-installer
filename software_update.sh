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

# Header
clear
echo -e "============================================================="
echo -e " HACKERBOT SOFTWARE CHECK"
echo -e "============================================================="
echo

# Setup
HOME_DIR="/home/$(whoami)"
LOG_DIR="$HOME_DIR/hackerbot/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update_$(date +'%Y-%m-%d_%H-%M-%S').log"
touch "$LOG_FILE"

# Check for Raspberry Pi 5
echo "[INFO] Checking hardware..."
if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
    echo "[OK] System is a Raspberry Pi 5."
else
    echo "[WARNING] This script is designed for Raspberry Pi 5. Proceeding with caution."
fi
echo

# Start system check
(
    echo "[STEP] Checking APT packages..."
    REQUIRED_APT_PACKAGES=("python3" "python3-pip" "git" "curl" "build-essential" "nodejs" "npm")
    MISSING_APT_PACKAGES=()

    for PACKAGE in "${REQUIRED_APT_PACKAGES[@]}"; do
        if ! dpkg -s "$PACKAGE" &>/dev/null; then
            echo "[MISSING] $PACKAGE is NOT installed."
            MISSING_APT_PACKAGES+=("$PACKAGE")
        fi
    done

    if [ ${#MISSING_APT_PACKAGES[@]} -ne 0 ]; then
        echo "[INFO] Missing APT packages: ${MISSING_APT_PACKAGES[*]}"
        echo "[STEP] Installing missing APT packages..."
        sudo apt-get update >> "$LOG_FILE" 2>&1
        sudo apt-get install -y "${MISSING_APT_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
    else
        echo "[OK] All required APT packages are installed."
    fi
    echo

    echo "[STEP] Checking Python virtual environment..."
    if [[ -z "${VIRTUAL_ENV:-}" ]]; then
        echo "[ERROR] 'hackerbot_venv' virtual environment is NOT activated!"
        echo "Please activate it using: source ~/hackerbot/hackerbot_venv/bin/activate"
        exit 1
    else
        echo "[OK] Virtual environment is activated."
    fi
    echo

    echo "[STEP] Checking PIP packages..."
    REQUIRED_PIP_PACKAGES=("blinker" "click" "Flask" "flask-cors" "itsdangerous" "Jinja2" \
                          "MarkupSafe" "pip" "pyserial" "python-dotenv" "setuptools" "Werkzeug")
    MISSING_PIP_PACKAGES=()
    INSTALLED_PIP_PACKAGES=$(pip list --format=columns | awk '{print $1}' | tail -n +3)

    for PIP_PACKAGE in "${REQUIRED_PIP_PACKAGES[@]}"; do
        if ! echo "$INSTALLED_PIP_PACKAGES" | grep -qw "$PIP_PACKAGE"; then
            echo "[MISSING] $PIP_PACKAGE is NOT installed."
            MISSING_PIP_PACKAGES+=("$PIP_PACKAGE")
        fi
    done

    if [ ${#MISSING_PIP_PACKAGES[@]} -ne 0 ]; then
        echo "[STEP] Installing missing PIP packages..."
        pip install "${MISSING_PIP_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
    else
        echo "[OK] All required PIP packages are installed."
    fi
    echo

) || {
    echo -e "\n[ERROR] An error occurred during update process."
    echo "Check log at: $LOG_FILE"
    exit 1
}

echo -e "\n[OK] Completed Software Check and Update."
echo "Log saved at: $LOG_FILE"
