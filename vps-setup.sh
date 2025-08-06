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

    apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable --now docker
    echo -e "${GREEN}✅ Docker berhasil diinstal.${NC}"
}

# ========== Menu 8 ==========
function install_chromium_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}❌ Docker belum terinstal. Install Docker terlebih dahulu (menu 7).${NC}"
        return
    fi

    echo -e "${BLUE}[INFO] Konfigurasi Chromium Docker Container...${NC}"
    
    read -p "Username: " USERNAME
    while [[ -z "$USERNAME" ]]; do
        echo -e "${RED}Username tidak boleh kosong!${NC}"
        read -p "Username: " USERNAME
    done
    
    read -s -p "Password: " PASSWORD
    echo ""
    while [[ -z "$PASSWORD" ]]; do
        echo -e "${RED}Password tidak boleh kosong!${NC}"
        read -s -p "Password: " PASSWORD
        echo ""
    done
    
    read -p "Timezone (default: Asia/Jakarta): " TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Jakarta}
    
    read -p "HTTP Port (default: 3010): " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-3010}
    
    read -p "HTTPS Port (default: 3011): " HTTPS_PORT
    HTTPS_PORT=${HTTPS_PORT:-3011}

    # Validasi port
    if ! [[ "$HTTP_PORT" =~ ^[0-9]+$ ]] || [ "$HTTP_PORT" -lt 1024 ] || [ "$HTTP_PORT" -gt 65535 ]; then
        echo -e "${RED}❌ HTTP Port tidak valid (gunakan 1024-65535).${NC}"
        return
    fi
    
    if ! [[ "$HTTPS_PORT" =~ ^[0-9]+$ ]] || [ "$HTTPS_PORT" -lt 1024 ] || [ "$HTTPS_PORT" -gt 65535 ]; then
        echo -e "${RED}❌ HTTPS Port tidak valid (gunakan 1024-65535).${NC}"
        return
    fi

    # Set shm_size berdasarkan RAM
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [ $RAM_KB -lt 2097152 ]; then 
        SHM="256m"
    elif [ $RAM_KB -lt 4194304 ]; then 
        SHM="512m"
    else 
        SHM="1g"
    fi

    # Buat direktori dan file konfigurasi
    mkdir -p ~/chromium
    cd ~/chromium

    # Stop container jika sudah ada
    docker stop chromium 2>/dev/null || true
    docker rm chromium 2>/dev/null || true

    # Hapus file compose lama jika ada
    rm -f docker-compose.yaml docker-compose.yml

    echo -e "${BLUE}[INFO] Membuat konfigurasi Docker Compose...${NC}"

    cat <<EOF > docker-compose.yml
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - CUSTOM_USER=$USERNAME
      - PASSWORD=$PASSWORD
      - SUBFOLDER=/
      - TITLE=Chromium
    volumes:
      - ./config:/config
    ports:
      - "$HTTP_PORT:3000"
      - "$HTTPS_PORT:3001"
    shm_size: $SHM
    restart: unless-stopped
EOF

    echo -e "${BLUE}[INFO] Menjalankan Chromium container...${NC}"
    
    # Install docker-compose jika belum ada
    if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
        echo -e "${BLUE}[INFO] Installing docker-compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    # Jalankan container
    if command -v docker-compose &>/dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi

    # Tunggu container siap
    echo -e "${BLUE}[INFO] Menunggu container siap...${NC}"
    sleep 10

    # Cek status container
    if docker ps | grep -q chromium; then
        PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")
        
        echo -e ""
        echo -e "${GREEN}✅ Chromium berhasil dijalankan!${NC}"
        echo -e "${GREEN}===========================================${NC}"
        echo -e "🌐 HTTP  : ${YELLOW}http://$PUBLIC_IP:$HTTP_PORT${NC}"
        echo -e "🔒 HTTPS : ${YELLOW}https://$PUBLIC_IP:$HTTPS_PORT${NC}"
        echo -e "👤 Username: ${YELLOW}$USERNAME${NC}"
        echo -e "🔑 Password: ${YELLOW}[HIDDEN]${NC}"
        echo -e "${GREEN}===========================================${NC}"
        echo -e "${BLUE}💡 Tips:${NC}"
        echo -e "   • Gunakan HTTPS untuk keamanan yang lebih baik"
        echo -e "   • Jika HTTPS gagal, accept self-signed certificate"
        echo -e "   • Container akan restart otomatis jika VPS reboot"
        echo -e ""
        echo -e "${BLUE}🔧 Management:${NC}"
        echo -e "   • Stop: ${YELLOW}cd ~/chromium && docker-compose down${NC}"
        echo -e "   • Start: ${YELLOW}cd ~/chromium && docker-compose up -d${NC}"
        echo -e "   • Logs: ${YELLOW}docker logs chromium${NC}"
    else
        echo -e "${RED}❌ Gagal menjalankan Chromium container.${NC}"
        echo -e "${YELLOW}Cek logs: docker logs chromium${NC}"
        return 1
    fi
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
