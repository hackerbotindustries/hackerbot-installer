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

# Define startup commands
FLASK_CRON="@reboot bash -c 'source ~/hackerbot/hackerbot_venv/bin/activate && ./hackerbot/hackerbot-flask-api/launch_flask_api.sh' &"
COMMAND_CENTER_CRON="@reboot bash -c './hackerbot/hackerbot-command-center/launch_command_center.sh' &"

# Function to check if a cron entry exists
is_enabled() {
    crontab -l 2>/dev/null | grep -Fxq "$1"
}

# Introduction
echo "
=================================================================
Hackerbot Startup Configuration

This tool lets you choose whether the Flask API and Command Center
should automatically start when the system boots.

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

# Menu loop
while true; do
    echo "
Choose an option:
1) Enable Flask API at startup
2) Enable Command Center at startup
3) Disable both (remove from startup)
4) Exit
"
    read -rp "Enter your choice (1-4): " choice

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
            echo "Exiting. Your configuration is saved."
            break
            ;;
        *)
            echo "Invalid input. Please enter 1, 2, 3, or 4."
            ;;
    esac
done
