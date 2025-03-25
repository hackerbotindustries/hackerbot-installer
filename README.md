# hackerbot_install

This repository provides installation instructions and scripts for setting up the HackerBot software.

---

### Prerequisites

Before you begin, ensure that you have the following:

- A Linux-based system (Raspberry Pi 5 is recommended)
- Git installed on your system
- Necessary permissions to run shell scripts

---

### Installation

Follow the following to install the HackerBot software:
   ```bash
   cd ~
   git clone https://github.com/hackerbotindustries/hackerbot-installer.git
   cd ~/hackerbot-installer
   ./install.sh
   ```
---

NOTE: Do not run `install.sh` from a VNC client. It can hang.

### Check and Update Software

To check and update the software, run the below commands:
   ```bash
   cd ~/hackerbot-installer
   ./install.sh
   ```

---
