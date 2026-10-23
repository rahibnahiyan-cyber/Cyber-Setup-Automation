pkg update && pkg upgrade -y
termux-setup-storage
pkg install nmap -y
pkg update && pkg upgrade -y
pkg install curl wget git proot -y
apt update && pkg install wget -y && pkg upgrade -y -o Dpkg::Options::="--force-confnew" && clear && wget -qO install.sh https://raw.githubusercontent.com/xiv3r/Kali-Linux-Termux/refs/heads/main/kali_nethunter/install.sh && chmod +x install.sh && bash install.sh
