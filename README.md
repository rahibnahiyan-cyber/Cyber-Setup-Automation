# 🚀 My Personal - Kali Setup & Security Lab

This repository is a personal collection of scripts, environment setup files, and practice projects used for Linux system configuration and web application security testing.

It contains the main setup scripts used for installing and configuring a Kali Linux environment, plus smaller learning and testing projects related to Python scripting and authentication/session security.

## Repository Overview

This repo includes:

- Kali Linux installer for XFCE / GNOME / KDE Plasma
- Termux-based Kali bootstrap helper
- Desktop wallpaper collection
- Programming practice scripts
- Authentication and session security test lab
- Security notes and supporting files

## Main Files and Folders

```text
My-Personal/
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

The main installer script is:

- `install.sh`

This script is designed for Kali Linux and supports the following desktop environments:

- XFCE
- GNOME
- KDE Plasma

It can install or configure:

- package updates and upgrades
- zram swap
- VS Code
- VirtualBox
- Google Chrome
- OBS Studio
- Kdenlive
- LibreOffice

### Usage

```bash
git clone https://github.com/rahibnahiyan-cyber/My-Personal.git
cd My-Personal
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

The repository also contains:

- `install_termux.sh`

This helper script is used to prepare a Termux environment and bootstrap a Kali Linux installation inside it.

### Usage

```bash
git clone https://github.com/rahibnahiyan-cyber/My-Personal.git
cd My-Personal
bash install_termux.sh
```

## 3) Programming Practice

The `programming-test/` folder contains small Python practice scripts and learning exercises.

Example:

- `programming-test/practice.py`

This section is mainly for testing code logic, quick experiments, and improving scripting skills.

## 4) Web Authentication / Session Security Lab

The `web-test/auth-session-lab/` folder is a focused security testing environment that includes:

- `server.py` - main web app for authentication/session testing
- `run_all_tests.py` - runs the test suite
- `test_invalid_login.py` - invalid login handling
- `test_logout.py` - logout behavior
- `test_profile_access.py` - profile access restrictions
- `test_admin_access.py` - admin authorization checks
- `test_session_rotation.py` - session rotation and regeneration
- `test_session_timeout.py` - timeout behavior
- `test_security_headers.py` - HTTP security headers validation
- cookie and timeout sample files for testing real-world session scenarios

This lab is useful for understanding:

- authentication flows
- session fixation
- logout handling
- authorization checks
- secure cookie configuration
- timeout and session expiration
- security header enforcement

## 5) Personal Use and Learning

This repository is primarily for personal setup automation and cybersecurity learning. It combines practical system administration tasks with web security concepts and coding exercises.

## License

This project is licensed under the terms provided in the `LICENSE` file.

## Security Policy

For security-related concerns, see `SECURITY.md`.

## Quick Start

```bash
git clone https://github.com/rahibnahiyan-cyber/My-Personal.git
cd My-Personal
```

Then choose the relevant setup:

```bash
bash install.sh
```

or

```bash
bash install_termux.sh
```

This repository is best used as a personal toolkit for fresh Kali setup, scripting practice, and authentication/security testing.
