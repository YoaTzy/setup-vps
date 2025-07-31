#!/bin/bash

# ========== Warna ==========
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

# ========== Deteksi OS & Info ==========
function detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$PRETTY_NAME
    else
        OS_NAME="Unknown"
    fi
}

function get_vps_info() {
    CPU_CORES=$(nproc)
    RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
    SWAP_TOTAL=$(free -h | awk '/Swap:/ {print $2}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')
}

# ========== Menu 1 ==========
function enable_root_login() {
    echo -e "${BLUE}[INFO] Mengaktifkan login root...${NC}"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    sed -i 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#*KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

    echo -e "${YELLOW}Masukkan password root:${NC}"
    passwd root

    systemctl restart ssh || systemctl restart sshd
    echo -e "${GREEN}[OK] Root login diaktifkan.${NC}"
}

# ========== Menu 2 ==========
function change_port() {
    echo -e "${YELLOW}Masukkan port SSH baru:${NC}"
    read -p "Port: " PORT

    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo -e "${RED}❌ Port tidak valid.${NC}"
        return
    fi

    sed -i "s/^#*Port .*/Port $PORT/" /etc/ssh/sshd_config
    systemctl restart ssh || systemctl restart sshd
    echo -e "${GREEN}[OK] SSH berjalan di port $PORT${NC}"
}

# ========== Menu 3 ==========
function swap_manager() {
    read -p "Ukuran swap (contoh: 2G): " SIZE
    read -p "Swappiness (0-100, default 80): " SWAPN
    SWAPN=${SWAPN:-80}

    BYTES=$(echo $SIZE | awk '{if($1~/G/) {gsub("G","",$1); print $1*1024*1024*1024} else if($1~/M/) {gsub("M","",$1); print $1*1024*1024}}')

    if [[ "$BYTES" -lt 134217728 ]]; then
        echo -e "${RED}❌ Swap terlalu kecil.${NC}"
        return
    fi

    swapoff -a
    rm -f /swapfile
    sed -i '/swap/d' /etc/fstab

    fallocate -l "$SIZE" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=$(($BYTES / 1024 / 1024))
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "vm.swappiness=$SWAPN" >> /etc/sysctl.conf
    sysctl -w vm.swappiness=$SWAPN

    echo -e "${GREEN}✅ Swap berhasil dibuat.${NC}"
    free -h
}

# ========== Menu 4 ==========
function install_speedtest() {
    apt update
    apt install -y curl gnupg1 apt-transport-https
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    apt install -y speedtest
    echo -e "${GREEN}✅ Speedtest CLI terinstal. Jalankan: speedtest${NC}"
}

# ========== Menu 5 ==========
function install_vnstat() {
    apt update
    apt install -y vnstat
    systemctl enable --now vnstat
    echo -e "${GREEN}✅ vnStat terinstal. Jalankan: vnstat${NC}"
}

# ========== Menu 6 ==========
function install_neofetch() {
    apt update
    apt install -y neofetch
    if ! grep -q neofetch ~/.bashrc; then echo "neofetch" >> ~/.bashrc; fi
    echo -e "${GREEN}✅ neofetch ditambahkan ke bash login.${NC}"
}

# ========== Menu 7 ==========
function install_docker() {
    if command -v docker &>/dev/null; then
        echo -e "${GREEN}✅ Docker sudah terinstal.${NC}"
        return
    fi

    apt update
    apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update && apt install -y docker-ce docker-ce-cli containerd.io
    systemctl enable --now docker
    echo -e "${GREEN}✅ Docker berhasil diinstal.${NC}"
}

# ========== Menu 8 ==========
function install_chromium_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}❌ Docker belum terinstal.${NC}"
        return
    fi

    read -p "Username: " USERNAME
    read -s -p "Password: " PASSWORD
    echo ""
    read -p "Timezone (default: Asia/Jakarta): " TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Jakarta}
    read -p "HTTP Port (default: 3010): " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-3010}
    read -p "HTTPS Port (default: 3011): " HTTPS_PORT
    HTTPS_PORT=${HTTPS_PORT:-3011}
    read -p "No window border (y/n, default: y): " NO_DECOR
    NO_DECOR=${NO_DECOR:-y}
    read -p "Disable fullscreen? (y/n, default: n): " NO_FULL
    NO_FULL=${NO_FULL:-n}

    RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [ $RAM_MB -lt 2097152 ]; then SHM="256mb"
    elif [ $RAM_MB -lt 4194304 ]; then SHM="512mb"
    else SHM="1gb"
    fi

    mkdir -p ~/chromium && cd ~/chromium

    cat <<EOF > docker-compose.yaml
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    environment:
      - CUSTOM_USER=$USERNAME
      - PASSWORD=$PASSWORD
      - CUSTOM_PORT=3000
      - CUSTOM_HTTPS_PORT=3001
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
      $( [[ "$NO_DECOR" == "y" ]] && echo "- NO_DECOR=true" )
      $( [[ "$NO_FULL" == "y" ]] && echo "- NO_FULL=true" )
    ports:
      - "$HTTP_PORT:3000"
      - "$HTTPS_PORT:3001"
    volumes:
      - ./config:/config
    shm_size: "$SHM"
    restart: unless-stopped
EOF

    docker compose down || true
    docker compose up -d
    echo -e "${GREEN}✅ Chromium berjalan di http://$(curl -s ifconfig.me):$HTTP_PORT${NC}"
}

# ========== Menu Utama ==========
function main_menu() {
    clear
    detect_os
    get_vps_info

    echo -e "${GREEN}==== VPS SETUP MENU ====${NC}"
    echo -e "🖥️ OS: ${YELLOW}$OS_NAME${NC}"
    echo -e "🧠 CPU: ${YELLOW}$CPU_CORES core${NC}"
    echo -e "💾 RAM: ${YELLOW}$RAM_TOTAL${NC}"
    echo -e "📦 SWAP: ${YELLOW}$SWAP_TOTAL${NC}"
    echo -e "🗃️ DISK TOTAL: ${YELLOW}$DISK_TOTAL${NC}"
    echo -e "🧩 DISK FREE : ${YELLOW}$DISK_FREE${NC}"
    echo ""
    echo "1. 🔐 Enable root login"
    echo "2. 🔁 Ganti port SSH"
    echo "3. 💾 Swap RAM Manager"
    echo "4. 🚀 Install Speedtest CLI"
    echo "5. 📈 Install vnStat"
    echo "6. 🎨 Install neofetch (bashrc)"
    echo "7. 🐳 Install Docker"
    echo "8. 🌐 Deploy Chromium via Docker"
    echo "0. ❌ Keluar"
    echo ""

    read -p "Pilih menu [0-8]: " CHOICE
    case "$CHOICE" in
        1) enable_root_login ;;
        2) change_port ;;
        3) swap_manager ;;
        4) install_speedtest ;;
        5) install_vnstat ;;
        6) install_neofetch ;;
        7) install_docker ;;
        8) install_chromium_docker ;;
        0) exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
    esac

    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
    main_menu
}

main_menu
