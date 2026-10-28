# 🔐 Cyber Setup Automation

This repository is created for setting up a fresh Kali Linux machine on a new PC and automating the environment for cybersecurity learning, system customization, and ethical hacking practice.

The main workflow is simple:

```bash
git clone https://github.com/rahibnahiyan-cyber/Cyber-Setup-Automation.git
cd Cyber-Setup-Automation
bash install.sh
```

This repo is meant to help with:

- fresh Kali Linux installation and base setup
- desktop environment configuration
- software installation and system automation
- wallpaper collection and customization
- ethical hacking learning practice
- Python scripting and web security exercises

## Purpose

This project is built for personal cybersecurity workflow automation. Whenever I set up a new Kali Linux machine, I can clone this repository, run the installer, and get a ready-to-use environment for security testing and learning.

It also includes personal practice folders for:

- `programming-test/` — Python and scripting practice
- `web-test/` — web security and session/auth testing practice

These two folders will be updated regularly as part of my ethical hacking learning journey.

## Repository Structure

```text
Cyber-Setup-Automation/
├── README.md
├── LICENSE
├── SECURITY.md
├── install.sh
├── install_termux.sh
├── Wallpaper/
│   ├── 01.jpg
│   ├── hacker-wallpaper.jpg
│   └── ...
├── programming-test/
│   ├── practice.py
│   └── __pycache__/
└── web-test/
    └── auth-session-lab/
        ├── server.py
        ├── run_all_tests.py
        ├── test_admin_access.py
        ├── test_invalid_login.py
        ├── test_logout.py
        ├── test_profile_access.py
        ├── test_security_headers.py
        ├── test_session_rotation.py
        ├── test_session_timeout.py
        ├── timeout_check.py
        └── cookies.txt
```

## 1) Kali Linux Setup

The main install script is:

- `install.sh`

This script is designed for Kali Linux and helps automate the setup of a working cybersecurity environment, including system packages and common tools.

### Usage

```bash
git clone https://github.com/rahibnahiyan-cyber/Cyber-Setup-Automation.git
cd Cyber-Setup-Automation
bash install.sh
```

### Useful Options

```bash
bash install.sh --help
bash install.sh --verify
bash install.sh --skip-vscode
bash install.sh --skip-chrome
bash install.sh --skip-virtualbox
```

## 2) Wallpaper Setup

The `Wallpaper/` directory contains multiple wallpaper images for Kali Linux customization.

After installing the OS, I can select a wallpaper from this folder to personalize the desktop environment.

This helps make the system feel more comfortable and aligned with a cyber/security aesthetic.

## 3) Programming Practice

The `programming-test/` folder is used for:

- Python learning
- scripting exercises
- logic testing
- automation experiments

Current file:

- `programming-test/practice.py`

This section will be updated regularly as part of my coding and security practice.

## 4) Web Testing / Ethical Hacking Practice

The `web-test/` folder contains security labs for learning about:

- authentication flows
- authorization checks
- session handling
- logout behaviors
- security headers
- session rotation and timeout

The main lab is:

- `web-test/auth-session-lab/`

This folder is meant for ethical hacking learning and practical web security testing.

These files are maintained and updated regularly as my learning progresses.

## 5) Quick Start

```bash
git clone https://github.com/rahibnahiyan-cyber/Cyber-Setup-Automation.git
cd Cyber-Setup-Automation
bash install.sh
```

Then:

- choose a wallpaper from `Wallpaper/`
- use `programming-test/` for scripting practice
- use `web-test/` for ethical hacking and web security learning

## License

This project is licensed under the terms described in the `LICENSE` file.

## Security Policy

For security-related concerns, refer to `SECURITY.md`.

## Notes

This repository is intended for:

- Kali Linux setup automation
- personal cybersecurity environment setup
- wallpaper customization
- ethical hacking education
- Python and shell scripting practice
- regular web security learning updates

This project continues to evolve as a personal toolkit for cyber setup, practice, and learning.
