# Cyber Setup Automation

A personal Kali Linux setup automation repository for preparing a cyber-focused workstation, organizing tools, practicing web security exercises, and keeping setup notes in one place.

This repository combines environment setup scripts, personal project folders, wallpaper assets, and security testing exercises for learning and experimentation.

## Overview

The project is designed to help with:

- Installing and configuring Kali Linux tools and software
- Organizing a cyber-themed desktop environment
- Saving custom wallpaper and visual assets
- Practicing programming and Python scripts
- Testing authentication and session security concepts in a local lab
- Keeping setup notes and experiments centralized

## Repository Structure

```text
Cyber-Setup-Automation/
├── README.md
├── LICENSE
├── SECURITY.md
├── Kali Setup.txt
├── Projects/
│   └── New Folder/
├── Wallpaper/
│   ├── 01.jpg
│   ├── 02.jpg
│   ├── Kali nethunter Image.jpg
│   └── ...
├── programming-test/
│   ├── practice.py
│   └── __pycache__/
└── web-test/
    └── auth-session-lab/
        ├── server.py
        ├── server_before_delete_lab.py
        ├── server_before_idor.py
        ├── server_before_update_lab.py
        ├── run_all_tests.py
        ├── test_admin_access.py
        ├── test_invalid_login.py
        ├── test_logout.py
        ├── test_profile_access.py
        ├── test_security_headers.py
        ├── test_session_rotation.py
        ├── test_session_timeout.py
        ├── timeout_check.py
        ├── cookies.txt
        └── ...
```

## Included Files

### Kali Setup.txt
Contains a personal installation checklist for setting up a Kali-based machine. It includes package installations for:

- zram support
- Google Chrome
- Free Download Manager
- VirtualBox and guest additions
- VS Code and useful extensions
- Flatpak support
- Multimedia and system tools
- Tor Browser and related utilities

### Projects/
A folder for personal project work and experiments.

### Wallpaper/
A collection of cyber, hacker, terminal, and dark-themed wallpapers used for desktop customization.

### programming-test/
Contains Python learning and practice files, including simple script experimentation.

### web-test/auth-session-lab/
A security-focused local web testing lab for studying:

- authentication flows
- session fixation and session management
- logout behavior
- privilege checks and access control
- security headers
- session timeout and rotation
- IDOR and update/delete lab scenarios

## Purpose of the Repository

This repo acts as a personal cyber setup and learning environment, combining:

- OS setup automation
- security testing lab notes
- desktop customization assets
- Python practice files
- project organization

## Notes

- This repository is personal and intended for learning, experimentation, and workflow organization.
- Use the included security lab only in authorized and controlled environments.
- The project is centered around Kali Linux, Python, and web security practice.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Security Policy

Please review [SECURITY.md](SECURITY.md) for the repository security policy and reporting guidance.
