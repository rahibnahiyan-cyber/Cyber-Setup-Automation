# Lab Setup

A personal Kali Linux setup and learning repository. It collects a Kali workstation setup checklist, desktop wallpapers, a small Python practice script, and a local web authentication/session testing lab.

> **Scope:** The web tests are for learning in a local, controlled environment. Only test systems and accounts that you own or have explicit permission to assess.

## Repository contents

```text
.
├── Kali Setup.txt                 # Kali package and workstation setup commands
├── LICENSE                        # MIT License
├── README.md
├── SECURITY.md                    # Security reporting guidance
├── Projects/
│   └── New Folder/
│       └── domain.txt             # Empty placeholder
├── Wallpaper/                     # Desktop wallpaper and image assets
├── programming-test/
│   └── practice.py                # Python practice file
└── web-test/
    └── auth-session-lab/          # Local authentication/session lab and test artifacts
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
        └── *.txt                  # Cookie/session and test notes
```

## What's here

### Kali setup checklist

[`Kali Setup.txt`](Kali%20Setup.txt) contains commands and notes for configuring a Kali workstation. Topics include zram, Google Chrome, Free Download Manager, VirtualBox, Visual Studio Code and extensions, Flatpak, and desktop/system utilities. Review the commands and package sources before running them; adapt them to your system.

### Wallpaper

`Wallpaper/` contains image assets for desktop customization, including Kali, terminal, and cyber-themed wallpapers.

### Python practice

`programming-test/practice.py` is a small Python practice file.

### Local authentication/session lab

`web-test/auth-session-lab/` contains a Python server, test scripts, earlier lab server versions, and text files used as test artifacts. The scripts cover authentication and invalid login behavior, logout, profile/admin access checks, security headers, session rotation, and timeout checks. The lab also includes scenarios relating to update/delete behavior and insecure direct object references (IDOR).

Run or inspect the lab only in an isolated local environment, and verify its configuration before starting the server or tests.

## License and security

This project is available under the [MIT License](LICENSE). For security reporting guidance, see [SECURITY.md](SECURITY.md).
