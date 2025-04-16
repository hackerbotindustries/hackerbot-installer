#!/bin/bash
################################################################################
# Copyright (c) 2025 Hackerbot Industries LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Created By: Allen Chien
# Created:    April 2025
# Updated:    2025.04.14
#
# This script configures startup settings for the Hackerbot software.
#
# Special thanks to the following for their code contributions to this codebase:
# Allen Chien - https://github.com/AllenChienXXX
################################################################################

# Helper: Add a cron entry if not already present
add_to_cron() {
    local cron_entry="$1"
    (crontab -l 2>/dev/null | grep -Fxv "$cron_entry"; echo "$cron_entry") | crontab -
}

# Helper: Remove a specific cron entry
remove_from_cron() {
    local cron_entry="$1"
    crontab -l 2>/dev/null | grep -Fxv "$cron_entry" | crontab -
}

# Constants
VENV_LINE="source $HOME/hackerbot/hackerbot_venv/bin/activate"
BASHRC="$HOME/.bashrc"
FLASK_CRON="@reboot bash -c '$VENV_LINE && ./hackerbot/hackerbot-flask-api/launch_flask_api.sh' &"
COMMAND_CENTER_CRON="@reboot bash -c './hackerbot/hackerbot-command-center/launch_command_center.sh' &"

# Function to check if a cron entry exists
is_enabled() {
    crontab -l 2>/dev/null | grep -Fxq "$1"
}

# Function to check if venv line is in bashrc
venv_is_enabled() {
    grep -Fxq "$VENV_LINE" "$BASHRC"
}

# Introduction
echo "
=================================================================
Hackerbot Startup Configuration

This tool lets you choose whether the Flask API and Command Center
should automatically start when the system boots.

You can also configure whether your bash shell activates the virtual
environment automatically by adding it to ~/.bashrc.

Note:
If enabled, these services may occupy the serial port and prevent
other programs from using it.

You can change these settings at any time by re-running this script.
=================================================================
"

# Show current status
echo "Current startup configuration:"
if is_enabled "$FLASK_CRON"; then
    echo " - Flask API: ENABLED at startup"
else
    echo " - Flask API: DISABLED at startup"
fi

if is_enabled "$COMMAND_CENTER_CRON"; then
    echo " - Command Center: ENABLED at startup"
else
    echo " - Command Center: DISABLED at startup"
fi

if venv_is_enabled; then
    echo " - hackerbot_venv: ENABLED in ~/.bashrc"
else
    echo " - hackerbot_venv: DISABLED in ~/.bashrc"
fi

# Menu loop
while true; do
    echo "
Choose an option:
1) Enable Flask API at startup
2) Enable Command Center at startup
3) Disable both (remove from startup)
4) Enable Python venv sourcing in ~/.bashrc
5) Disable Python venv sourcing in ~/.bashrc
6) Exit
"
    read -rp "Enter your choice (1-6): " choice

    case $choice in
        1)
            add_to_cron "$FLASK_CRON"
            echo "Flask API has been added to startup."
            ;;
        2)
            add_to_cron "$COMMAND_CENTER_CRON"
            echo "Command Center has been added to startup."
            ;;
        3)
            remove_from_cron "$FLASK_CRON"
            remove_from_cron "$COMMAND_CENTER_CRON"
            echo "All startup entries have been removed."
            ;;
        4)
            if venv_is_enabled; then
                echo "Python venv activation is already enabled in ~/.bashrc"
            else
                echo "$VENV_LINE" >> "$BASHRC"
                echo "Python venv activation added to ~/.bashrc"
            fi
            ;;
        5)
            if venv_is_enabled; then
                sed -i "\|$VENV_LINE|d" "$BASHRC"
                echo "Python venv activation removed from ~/.bashrc"
            else
                echo "Python venv activation is already disabled."
            fi
            ;;
        6)
            echo "Exiting. Your configuration is saved."
            break
            ;;
        *)
            echo "Invalid input. Please enter a number between 1 and 6."
            ;;
    esac
done
