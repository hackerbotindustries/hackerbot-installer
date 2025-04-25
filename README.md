![HackerBot](images/transparent_hb_horizontal_industries_.png)
# hackerbot-install

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
   bash install.sh
   ```
Now open a new terminal window and you shall see the hackerbot_venv activated!
---

### Check and Update Software

To check and update the software, run the below commands:
   ```bash
   cd ~/hackerbot-installer
   bash software_update.sh
   ```

To set some boot configurations, run:
   ```bash
   cd ~/hackerbot-installer
   bash boot_configure.sh
   ```
---

### Tests

For install.sh:
   ```bash
   cd ~/hackerbot-installer
   bats tests/test_install.bats
   ```
For software_update.sh:
   ```bash
   cd ~/hackerbot-installer
   bats tests/test_software_update.bats
   ```