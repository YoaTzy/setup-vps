#!/bin/bash

# ========== Warna ==========
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

# ========== Deteksi OS dan Info VPS ==========
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

function get_vps_info() {
    CPU_CORES=$(nproc)
    RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
    SWAP_TOTAL=$(free -h | awk '/Swap:/ {print $2}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
}

# ========== Menu 1: Enable root login ==========
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

# ========== Menu 2: Ganti Port SSH ==========
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

    systemctl restart ssh || systemctl restart sshd

    echo -e "${GREEN}✅ SSH sekarang berjalan di port $PORT_BARU!${NC}"
    echo -e "${BLUE}📌 Login SSH selanjutnya gunakan: ssh -p $PORT_BARU user@ip_address${NC}"
}

# ========== Menu 3: Swap Manager ==========
function swap_manager() {
    echo -e "${YELLOW}Masukkan ukuran swap (contoh: 4G, 2048M):${NC}"
    read -p "Ukuran: " SWAP_SIZE
    echo -e "${YELLOW}Masukkan nilai swappiness (0-100, default: 80):${NC}"
    read -p "Swappiness: " SWAPPINESS
    SWAPPINESS=${SWAPPINESS:-80}

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

# ========== Menu 4: Install Speedtest Ookla ==========
function install_speedtest() {
    echo -e "${BLUE}[INFO] Menginstal Speedtest CLI dari Ookla...${NC}"
    apt update
    apt install -y curl gnupg1 apt-transport-https

    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    apt install -y speedtest

    echo -e "${GREEN}✅ Speedtest CLI berhasil diinstal. Jalankan dengan: speedtest${NC}"
}

# ========== Menu 5: Install vnStat ==========
function install_vnstat() {
    echo -e "${BLUE}[INFO] Menginstal vnStat...${NC}"
    apt update
    apt install -y vnstat
    systemctl enable vnstat
    systemctl start vnstat
    echo -e "${GREEN}✅ vnStat berhasil diinstal. Jalankan dengan: vnstat${NC}"
}

# ========== Menu 6: Install neofetch ==========
function install_neofetch() {
    echo -e "${BLUE}[INFO] Menginstal neofetch dan menambahkan ke bashrc...${NC}"
    apt update
    apt install -y neofetch

    if ! grep -q neofetch ~/.bashrc; then
        echo "sleep 0.5" >> ~/.bashrc
        echo "neofetch" >> ~/.bashrc
    fi

    echo -e "${GREEN}✅ neofetch berhasil diinstal dan akan tampil setiap login shell.${NC}"
}

# ========== Main Menu ==========
function main_menu() {
    clear
    detect_os
    get_vps_info

    echo -e "${GREEN}==== VPS SETUP MENU ====${NC}"
    echo -e "🖥️ OS: ${YELLOW}$OS_NAME${NC}"
    echo -e "🧠 CPU Cores: ${YELLOW}$CPU_CORES${NC}"
    echo -e "💾 RAM: ${YELLOW}$RAM_TOTAL${NC}"
    echo -e "📦 Swap: ${YELLOW}$SWAP_TOTAL${NC}"
    echo -e "🗃️ Disk Total (/): ${YELLOW}$DISK_TOTAL${NC}"
    echo ""
    echo "1. 🔐 Enable root login via password"
    echo "2. 🔁 Ganti port SSH"
    echo "3. 💾 Swap RAM Manager"
    echo "4. 🚀 Install Speedtest (Ookla CLI)"
    echo "5. 📈 Install vnStat"
    echo "6. 🎨 Install neofetch (otomatis tampil di bash)"
    echo "0. ❌ Keluar"
    echo ""

    read -p "Pilih menu [0-6]: " PILIHAN
    case "$PILIHAN" in
        1) enable_root_login ;;
        2) change_port ;;
        3) swap_manager ;;
        4) install_speedtest ;;
        5) install_vnstat ;;
        6) install_neofetch ;;
        0) echo -e "${YELLOW}Keluar...${NC}" && exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" && sleep 2 && main_menu ;;
    esac
}

main_menu
