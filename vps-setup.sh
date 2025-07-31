#!/bin/bash

# Warna
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

# ====== Deteksi OS & Provider ======
function detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$PRETTY_NAME
        OS_ID=$ID
    else
        OS_NAME="Unknown"
        OS_ID="unknown"
    fi
}

function detect_provider_region() {
    if curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/ >/dev/null; then
        PROVIDER="AWS EC2"
        REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
    elif grep -iq "digitalocean" /sys/class/dmi/id/product_name 2>/dev/null; then
        PROVIDER="DigitalOcean"
        REGION="Unknown"
    elif grep -iq "Vultr" /sys/class/dmi/id/product_name 2>/dev/null; then
        PROVIDER="Vultr"
        REGION="Unknown"
    else
        PROVIDER="Generic VPS"
        REGION="Unknown"
    fi
}

# ===== MENU 1: Enable root login =====
function enable_root_login() {
    echo -e "${BLUE}[INFO] Mengaktifkan login root via password...${NC}"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    sed -i 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#*KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

    echo -e "${YELLOW}Masukkan password baru untuk root:${NC}"
    passwd root

    systemctl restart ssh || systemctl restart sshd
    echo -e "${GREEN}[OK] Login root dengan password telah diaktifkan.${NC}"
}

# ===== MENU 2: Ganti Port SSH =====
function change_port() {
    echo -e "${YELLOW}Masukkan port SSH baru yang ingin digunakan:${NC}"
    read -p "Port: " PORT_BARU

    if ! [[ "$PORT_BARU" =~ ^[0-9]+$ ]] || [ "$PORT_BARU" -lt 1 ] || [ "$PORT_BARU" -gt 65535 ]; then
        echo -e "${RED}❌ Port tidak valid! Harus berupa angka 1-65535.${NC}"
        return
    fi

    SSHD_CONFIG="/etc/ssh/sshd_config"

    echo -e "${BLUE}📄 Mengubah port SSH ke $PORT_BARU...${NC}"
    if grep -q "^Port" "$SSHD_CONFIG"; then
        sed -i "s/^Port .*/Port $PORT_BARU/" "$SSHD_CONFIG"
    else
        echo "Port $PORT_BARU" >> "$SSHD_CONFIG"
    fi

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl restart ssh.socket 2>/dev/null
    systemctl restart ssh.service || systemctl restart ssh

    yes | ufw enable
    ufw allow "$PORT_BARU"/tcp
    ufw delete allow 22/tcp 2>/dev/null || true
    ufw reload

    if ss -tuln | grep -q ":$PORT_BARU "; then
        echo -e "${GREEN}✅ SSH sekarang berjalan di port $PORT_BARU!${NC}"
    else
        echo -e "${RED}❌ SSH belum berjalan di port $PORT_BARU. Silakan cek konfigurasi manual.${NC}"
    fi

    echo -e "${BLUE}📌 Login SSH selanjutnya gunakan: ssh -p $PORT_BARU user@ip_address${NC}"
}

# ===== MENU 3: Swap Manager =====
function swap_manager() {
    echo -e "${YELLOW}Masukkan ukuran swap (contoh: 4G, 2048M):${NC}"
    read -p "Ukuran: " SWAP_SIZE
    echo -e "${YELLOW}Masukkan nilai swappiness (0-100, default: 80):${NC}"
    read -p "Swappiness: " SWAPPINESS
    SWAPPINESS=${SWAPPINESS:-80}

    # Validasi ukuran swap
    BYTES=$(echo $SWAP_SIZE | awk \
    '{size=$1; if(size~/G/) {gsub("G","",size); print size*1024*1024*1024} else if(size~/M/) {gsub("M","",size); print size*1024*1024} else {print size}}')

    if [[ "$BYTES" -lt 134217728 ]]; then
        echo -e "${RED}❌ Ukuran swap terlalu kecil. Minimal 128MB.${NC}"
        return
    fi

    echo -e "${BLUE}🧹 Menghapus swap lama (jika ada)...${NC}"
    swapoff -a
    sed -i '/swap/d' /etc/fstab
    rm -f /swapfile

    echo -e "${BLUE}📦 Membuat swapfile sebesar $SWAP_SIZE...${NC}"
    fallocate -l "$SWAP_SIZE" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=$(($BYTES/1024/1024))
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    echo "vm.swappiness=$SWAPPINESS" >> /etc/sysctl.conf
    sysctl -w vm.swappiness=$SWAPPINESS

    echo -e "${GREEN}✅ Swap berhasil diatur.${NC}"
    free -h
}

# ===== MAIN MENU =====
function main_menu() {
    clear
    detect_os
    detect_provider_region

    echo -e "${GREEN}==== VPS SETUP MENU ====${NC}"
    echo -e "🖥️ OS: ${YELLOW}$OS_NAME${NC}"
    echo -e "☁️ Provider: ${YELLOW}$PROVIDER${NC}"
    echo -e "🌍 Region: ${YELLOW}$REGION${NC}"
    echo ""
    echo "1. 🔐 Enable root login via password"
    echo "2. 🔁 Ganti port SSH"
    echo "3. 💾 Swap RAM Manager"
    echo "0. ❌ Keluar"
    echo ""

    read -p "Pilih menu [0-3]: " PILIHAN
    case "$PILIHAN" in
        1) enable_root_login ;;
        2) change_port ;;
        3) swap_manager ;;
        0) echo -e "${YELLOW}Keluar...${NC}" && exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" && sleep 2 && main_menu ;;
    esac
}

main_menu
