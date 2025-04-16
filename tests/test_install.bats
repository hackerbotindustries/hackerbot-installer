#!/usr/bin/env bats
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
# This script uses bats to test install.sh
#
# Special thanks to the following for their code contributions to this codebase:
# Allen Chien - https://github.com/AllenChienXXX
################################################################################

setup() {
  export TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export HOME_DIR="$HOME"
  export MOCK_LOG="$HOME/mock_commands.log"
  export SCRIPT_PATH="$BATS_TEST_DIRNAME/../install.sh"

  mkdir -p "$HOME/bin"

  for cmd in sudo apt-get python3 pip npm; do
    cat <<EOF > "$HOME/bin/$cmd"
#!/bin/bash
echo "[MOCK] $cmd \$@" >> "$MOCK_LOG"
EOF
    chmod +x "$HOME/bin/$cmd"
  done

  cat <<'EOF' > "$HOME/bin/git"
#!/bin/bash
echo "[MOCK] git $@" >> "$MOCK_LOG"
if [[ "$1" == "clone" ]]; then
  repo_url="$2"
  repo_name=$(basename "$repo_url" .git)
  mkdir -p "$repo_name"
fi
EOF
  chmod +x "$HOME/bin/git"

  export PATH="$HOME/bin:$PATH"

  cp "$SCRIPT_PATH" "$HOME/install.sh"
  chmod +x "$HOME/install.sh"

  sed -i 's/read -p "\(.*\)" \(.*\)/echo "\1"; \2="y"/g' "$HOME/install.sh"
  sed -i 's|^HOME_DIR=.*|HOME_DIR="$HOME"|' "$HOME/install.sh"
  sed -i "s|VENV_CMD=.*|VENV_CMD=\"source $HOME/hackerbot/hackerbot_venv/bin/activate\"|" "$HOME/install.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "Installer script runs successfully" {
  run bash "$HOME/install.sh"
  [ "$status" -eq 0 ]
}

@test "Creates expected directory structure" {
  run bash "$HOME/install.sh"
  [ -d "$HOME/hackerbot" ]
  [ -d "$HOME/hackerbot-installer/logs" ]
  [ -d "$HOME/hackerbot/hackerbot-python-package" ]
  [ -d "$HOME/hackerbot/hackerbot-flask-api" ]
  [ -d "$HOME/hackerbot/hackerbot-command-center" ]
}

@test "Modifies .bashrc to source venv activate" {
  run bash "$HOME/install.sh"
  grep -q "source $HOME/hackerbot/hackerbot_venv/bin/activate" "$HOME/.bashrc"
}

@test "Creates setup log file in logs directory" {
  run bash "$HOME/install.sh"
  find "$HOME/hackerbot-installer/logs" -type f -name 'setup_*.log' | grep -q .
}

@test "Mocked system commands are called during install" {
  run bash "$HOME/install.sh"
  [ -f "$MOCK_LOG" ]
  grep -q "\[MOCK\]" "$MOCK_LOG"
}

@test "Installer attempts to install required APT packages" {
  run bash "$HOME/install.sh"
  [ -f "$MOCK_LOG" ]

  required_packages=(python3 python3-pip git curl build-essential nodejs npm bats)

  for pkg in "${required_packages[@]}"; do
    grep -q "apt-get install" "$MOCK_LOG"
    grep -q "$pkg" "$MOCK_LOG"
  done
}