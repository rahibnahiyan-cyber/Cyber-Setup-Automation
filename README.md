# 🔐 Cyber Setup Automation

This repository contains a personal collection of automation scripts, environment bootstrap helpers, and security learning labs for Kali Linux setup and web application security testing.

It is designed to help automate the initial configuration of a Kali-based workstation and includes small practice projects for Python scripting, authentication testing, and session security analysis.

## Overview

This project includes:

- Kali Linux installer for XFCE / GNOME / KDE Plasma
- Termux-based Kali bootstrap helper
- Wallpaper collection for desktop customization
- Python scripting practice files
- Authentication and session security lab
- Supporting notes and project files

## Repository Structure

```text
Cyber-Setup-Automation/
├── README.md
├── LICENSE
├── SECURITY.md
├── install.sh
├── install_termux.sh
├── Wallpaper/
├── programming-test/
│   └── practice.py
├── web-test/
│   └── auth-session-lab/
│       ├── server.py
│       ├── run_all_tests.py
│       ├── test_admin_access.py
│       ├── test_invalid_login.py
│       ├── test_logout.py
│       ├── test_profile_access.py
│       ├── test_security_headers.py
│       ├── test_session_rotation.py
│       ├── test_session_timeout.py
│       ├── timeout_check.py
│       ├── cookies.txt
│       └── *.txt
└── ...
```

## 1) Kali Linux Installer

Main script:

- `install.sh`

This script is intended for Kali Linux and supports the following desktop environments:

- XFCE
- GNOME
- KDE Plasma

It can install and configure:

- system package upgrades
- zram swap
- VS Code
- VirtualBox
- Google Chrome
- OBS Studio
- Kdenlive
- LibreOffice

### Usage

```bash
git clone https://github.com/rahibnahiyan-cyber/Cyber-Setup-Automation.git
cd Cyber-Setup-Automation
bash install.sh
```

### Useful options

```bash
bash install.sh --help
bash install.sh --verify
bash install.sh --skip-vscode
bash install.sh --skip-chrome
bash install.sh --skip-virtualbox
```

## 2) Termux Setup Helper

This repository also contains:

- `install_termux.sh`

This helper prepares a Termux environment and can be used to bootstrap a Kali Linux installation inside it.

### Usage

```bash
git clone https://github.com/rahibnahiyan-cyber/Cyber-Setup-Automation.git
cd Cyber-Setup-Automation
bash install_termux.sh
```

## 3) Programming Practice

The `programming-test/` folder contains small Python scripts and experiments for logic testing and scripting practice.

Example:

- `programming-test/practice.py`

This section is mainly used for quick experiments, learning, and improving Python automation skills.

## 4) Web Authentication / Session Security Lab

The `web-test/auth-session-lab/` folder is a focused environment for testing authentication and session security behaviors. It includes:

- `server.py` — main web application for auth/session testing
- `run_all_tests.py` — runs the test suite
- `test_invalid_login.py` — invalid login handling
- `test_logout.py` — logout behavior
- `test_profile_access.py` — profile access restrictions
- `test_admin_access.py` — admin authorization checks
- `test_session_rotation.py` — session rotation and regeneration
- `test_session_timeout.py` — timeout behavior
- `test_security_headers.py` — HTTP security headers validation
- cookie and timeout sample files for realistic testing scenarios

This lab is useful for understanding:

- authentication flows
- session fixation
- logout handling
- authorization checks
- secure cookie configuration
- timeout and expiration
- header-based security enforcement

## 5) Purpose

This repository is intended for:

- fresh Kali Linux setup automation
- developer environment provisioning
- personal cybersecurity learning
- web security testing exercises
- Python and shell scripting practice

## License

This project is licensed under the terms described in the `LICENSE` file.

## Security Policy

For security-related concerns, refer to `SECURITY.md`.

## Quick Start

```bash
git clone https://github.com/rahibnahiyan-cyber/Cyber-Setup-Automation.git
cd Cyber-Setup-Automation
```

Then choose the installation path you need:

```bash
bash install.sh
```

or

```bash
bash install_termux.sh
```

This project is best used as a toolkit for Kali setup, system automation, and web security research.
