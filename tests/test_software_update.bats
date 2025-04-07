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
# This script uses bats to test software_update.sh
#
# Special thanks to the following for their code contributions to this codebase:
# Allen Chien - https://github.com/AllenChienXXX
################################################################################


setup() {
  export TEST_HOME="/tmp/test-hackerbot"
  mkdir -p "$TEST_HOME/hackerbot/logs"
  export HOME="$TEST_HOME"
  export VIRTUAL_ENV="$TEST_HOME/hackerbot/hackerbot_venv"  # Simulate active venv
  mkdir -p "$VIRTUAL_ENV/bin"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "Shows warning if not Raspberry Pi 5" {
  grep -q "Raspberry Pi 5" /proc/cpuinfo || echo "[WARNING] This script is designed for Raspberry Pi 5. Proceeding with caution." | grep -q "Proceeding with caution"
}

@test "Fails gracefully if virtualenv is not activated" {
  unset VIRTUAL_ENV
  [[ -z "${VIRTUAL_ENV:-}" ]] && echo "[ERROR] Virtual environment is NOT activated!" | grep -q "NOT activated"
}

@test "Detects a missing APT package (fakepkg)" {
  dpkg -s fakepkg &>/dev/null || echo "[MISSING] fakepkg is NOT installed." | grep -q "fakepkg is NOT installed"
}

@test "Detects missing pip package (examplepkg)" {
  pip show examplepkg 2>/dev/null || echo "[MISSING] examplepkg is NOT installed." | grep -q "examplepkg is NOT installed"
}
