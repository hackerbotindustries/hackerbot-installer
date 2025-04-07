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
# This script test the install scripts, run with bash "bash test_install.sh"
#
# Special thanks to the following for their code contributions to this codebase:
# Allen Chien - https://github.com/AllenChienXXX
################################################################################

# Test harness for ../install.sh

set -euo pipefail
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


SCRIPT_PATH="$(dirname "$0")/../install.sh"


# Use a temporary directory for testing
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"
export HOME_DIR="$HOME"
export MOCK_LOG="$HOME/mock_commands.log"

# Mock critical commands
mock_commands() {
  echo "[TEST] Setting up mocked system commands..."
  mkdir -p "$HOME_DIR/bin"

  # Generic mock for sudo, apt-get, python3, pip, npm
  for cmd in sudo apt-get python3 pip npm; do
    cat <<EOF > "$HOME_DIR/bin/$cmd"
#!/bin/bash
echo "[MOCK] $cmd \$@" >> "$MOCK_LOG"
EOF
    chmod +x "$HOME_DIR/bin/$cmd"
  done

  # Minimal git clone mock: only create top-level repo directory
  cat <<'EOF' > "$HOME_DIR/bin/git"
#!/bin/bash
echo "[MOCK] git $@" >> "$MOCK_LOG"
if [[ "$1" == "clone" ]]; then
  repo_url="$2"
  repo_name=$(basename "$repo_url" .git)
  mkdir -p "$repo_name"
fi
EOF

  chmod +x "$HOME_DIR/bin/git"

  export PATH="$HOME_DIR/bin:$PATH"
  echo "[TEST] Mock commands setup complete."
}


simulate_user_input() {
  echo "[TEST] Simulating user input responses..."
  export INPUT_SEQUENCE=$(
    cat <<EOF
y
y
y
EOF
  )
  export INPUT_INDEX=0
  function read() {
    local varname=$1
    local value=$(echo "$INPUT_SEQUENCE" | sed -n "$((++INPUT_INDEX))p")
    printf "%s\n" "$value"
    eval "$varname=\"$value\""
  }
  echo "[TEST] Input simulation initialized."
}

assert_file_exists() {
  echo "[TEST] Checking if file exists: $1"
  if [[ ! -e "$1" ]]; then
    echo -e "${RED}[FAIL] Expected file not found: $1${NC}"
    exit 1
  else
    echo -e "${GREEN}[PASS] File exists: $1${NC}"
  fi
}

assert_dir_exists() {
  echo "[TEST] Checking if directory exists: $1"
  if [[ ! -d "$1" ]]; then
    echo -e "${RED}[FAIL] Expected directory not found: $1${NC}"
    exit 1
  else
    echo -e "${GREEN}[PASS] Directory exists: $1${NC}"
  fi
}

assert_bashrc_contains() {
  local expected="$1"
  echo "[TEST] Verifying .bashrc contains: $expected"
  if grep -qF "$expected" "$HOME/.bashrc"; then
    echo -e "${GREEN}[PASS] .bashrc contains: $expected${NC}"
  else
    echo -e "${RED}[FAIL] .bashrc missing expected line: $expected${NC}"
    exit 1
  fi
}

assert_logfile_created() {
  echo "[TEST] Checking if setup log file was created..."
  LOG_DIR="$HOME/hackerbot/logs"
  FILE_FOUND=$(find "$LOG_DIR" -type f -name 'setup_*.log' | head -n 1)
  if [[ -n "$FILE_FOUND" ]]; then
    echo -e "${GREEN}[PASS] Log file created: $FILE_FOUND${NC}"
  else
    echo -e "${RED}[FAIL] No setup log file found in $LOG_DIR${NC}"
    exit 1
  fi
}

run_test() {
  echo "[TEST] Running installer test in fake HOME: $HOME_DIR"
  mock_commands
  simulate_user_input

  cp "$SCRIPT_PATH" "$HOME_DIR/install.sh"
  chmod +x "$HOME_DIR/install.sh"

  echo "[TEST] Patching script for auto-confirmation..."
  sed -i 's/read -p "\(.*\)" \(.*\)/echo "\1"; \2="y"/g' "$HOME_DIR/install.sh"

  echo "[TEST] Patching HOME_DIR in script to match test env..."
  sed -i 's|^HOME_DIR=.*|HOME_DIR="$HOME"|' "$HOME_DIR/install.sh"

  echo "[TEST] Patching VENV_CMD path in script to match test env..."
  sed -i "s|VENV_CMD=.*|VENV_CMD=\"source $HOME/hackerbot/hackerbot_venv/bin/activate\"|" "$HOME_DIR/install.sh"

  echo "[TEST] Executing the installer script (output hidden)..."
  if ! bash "$HOME_DIR/install.sh" > /dev/null 2>&1; then
    echo "[FAIL] Installer script exited with error."
    exit 1
  fi

  echo "[TEST] Verifying results..."
  assert_dir_exists "$HOME/hackerbot"
  assert_dir_exists "$HOME/hackerbot/logs"
  assert_dir_exists "$HOME/hackerbot/maps"
  assert_dir_exists "$HOME/hackerbot/hackerbot-python-package"
  assert_dir_exists "$HOME/hackerbot/hackerbot-flask-api"
  assert_dir_exists "$HOME/hackerbot/hackerbot-command-center"
  assert_bashrc_contains "source $HOME/hackerbot/hackerbot_venv/bin/activate"
  assert_logfile_created
  assert_file_exists "$MOCK_LOG"

  echo "[TEST PASSED] All checks completed successfully."
}

cleanup() {
  echo "[TEST] Cleaning up test environment..."
  rm -rf "$TEST_HOME"
  echo "[TEST] Removed temporary test directory."
}

trap cleanup EXIT
run_test
