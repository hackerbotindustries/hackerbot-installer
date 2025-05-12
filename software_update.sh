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
#
# Special thanks to the following for their code contributions to this codebase:
# Allen Chien - https://github.com/AllenChienXXX
################################################################################

set -euo pipefail  # Strict mode

# Header
clear
echo -e "============================================================="
echo -e " HACKERBOT SOFTWARE UPDATE"
echo -e "============================================================="
echo

# Setup
HOME_DIR="/home/$(whoami)"
LOG_DIR="$HOME_DIR/hackerbot/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update_$(date +'%Y-%m-%d_%H-%M-%S').log"
touch "$LOG_FILE"

# System check
if grep -q "Raspberry Pi 5" /proc/cpuinfo; then
    echo "[OK] System is a Raspberry Pi 5."
else
    echo "[WARNING] This script is designed for Raspberry Pi 5. Proceeding with caution."
fi

# Start system check
(
    echo "[STEP] Checking APT packages..."
    REQUIRED_APT_PACKAGES=(
        "python3"
        "python3-pip"
        "python3.11-venv"
        "git"
        "curl"
        "build-essential"
        "nodejs"
        "npm"
        "bats"
        "portaudio19-dev"
        "cmake"
        "libgtk-3-dev"
    )
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

    echo "[STEP] Checking PIP packages and versions..."
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

    MISSING_OR_WRONG_PIP_PACKAGES=()

    while read -r pkg version; do
        INSTALLED_VERSION=$(pip show "$pkg" 2>/dev/null | grep -i "^Version:" | awk '{print $2}' || echo "")
        if [[ -z "$INSTALLED_VERSION" ]]; then
            echo "[MISSING] $pkg is NOT installed."
            if [[ -z "$version" ]]; then
                MISSING_OR_WRONG_PIP_PACKAGES+=("${pkg}")
            else
                MISSING_OR_WRONG_PIP_PACKAGES+=("${pkg}==${version}")
            fi
        elif [[ -n "$version" && "$INSTALLED_VERSION" != "$version" ]]; then
            echo "[MISMATCH] $pkg version $INSTALLED_VERSION found, expected $version."
            MISSING_OR_WRONG_PIP_PACKAGES+=("${pkg}==${version}")
        fi
    done < <(for key in "${!REQUIRED_PIP_PACKAGES[@]}"; do echo "$key ${REQUIRED_PIP_PACKAGES[$key]}"; done)

    if [ ${#MISSING_OR_WRONG_PIP_PACKAGES[@]} -ne 0 ]; then
        echo "[STEP] Installing/upgrading PIP packages to exact versions..."
        pip install --upgrade "${MISSING_OR_WRONG_PIP_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
    else
        echo "[OK] All required PIP packages are installed and up-to-date."
    fi
    echo

    echo "[STEP] Checking and updating Hackerbot repositories..."
    cd "$HOME_DIR/hackerbot"

    REPOS=("hackerbot-python-package" "hackerbot-flask-api" "hackerbot-command-center" "hackerbot-tutorials")

    for repo in "${REPOS[@]}"; do
        if [ -d "$repo/.git" ]; then
            # echo "[UPDATE] Rebasing latest changes for $repo..."
            (cd "$repo" && git fetch --all >> "$LOG_FILE" 2>&1 && git rebase origin/main || git reset --hard origin/main) >> "$LOG_FILE" 2>&1
            # echo "[OK] Updated $repo."
        else
            echo "[CLONE] Cloning $repo..."
            git clone https://github.com/hackerbotindustries/$repo.git >> "$LOG_FILE" 2>&1 || {
                echo "[ERROR] Failed to clone $repo."
                exit 1
            }
            # echo "[OK] Cloned $repo."
        fi
    done
    echo "[OK] Hackerbot repositories are up-to-date."
    echo

) || {
    echo -e "\n[ERROR] An error occurred during update process."
    echo "Check log at: $LOG_FILE"
    exit 1
}

echo -e "[OK] Completed Software Update."
echo "Log saved at: $LOG_FILE"
