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

Follow these steps to install the HackerBot software:

1. **Clone the repository**  
   Open a terminal and navigate to your desired installation directory. Then, clone the repository by running:
   ```bash
   git clone git@github.com:AllenChienXXX/hackerbot_install.git
   ```

2. **Navigate to the cloned directory**  
   Change to the root directory of the cloned repository:
   ```bash
   cd hackerbot_install
   ```

3. **Run the installation script**  
   Make the script executable (if it’s not already) and run the installation script:
   ```bash
   chmod +x hackerbot_software_install.sh
   ./hackerbot_software_install.sh
   ```

   This will set up the necessary components for the HackerBot software.

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
