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
   cd hackerbot-installer
   ./hackerbot_software-install.sh
   ```


---

### Update Software

To update the software, follow these steps:

1. Navigate to the root of your local repository:
   ```bash
   cd hackerbot_install
   ```

2. Pull the latest changes from the repository:
   ```bash
   git pull origin main
   ```

3. Run the install script again to apply any updates:
   ```bash
   ./hackerbot_software_install.sh
   ```

---
