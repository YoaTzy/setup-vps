# 🚀 VPS Setup Assistant (All-in-One Script)

Script bash interaktif untuk konfigurasi awal VPS berbasis Linux (Ubuntu/Debian).  
Semua fitur ada dalam satu file — tanpa dependensi eksternal. Cocok untuk server AWS, DigitalOcean, Vultr, dan VPS lainnya.

---

## ✨ Fitur Utama

✅ Deteksi dan tampilkan spesifikasi lengkap server:  
 • Jumlah CPU  
 • RAM & Swap  
 • Disk Total dan Free  
✅ Menu interaktif (CLI)  
✅ Tanpa dependensi eksternal  
✅ Dukungan penuh Ubuntu & Debian

---

## 📋 Daftar Menu

| Menu | Fitur                                    | Keterangan                                       |
|------|------------------------------------------|--------------------------------------------------|
| 1️⃣  | Enable root login via password           | Mengaktifkan login sebagai root user             |
| 2️⃣  | Ganti port SSH                           | Ubah port default SSH (22) menjadi custom        |
| 3️⃣  | Swap RAM Manager                         | Buat/mengatur swap file dan swappiness          |
| 4️⃣  | Install Speedtest CLI                    | Speedtest dari Ookla (resmi)                     |
| 5️⃣  | Install vnStat                           | Monitoring bandwidth (persisten)                |
| 6️⃣  | Install neofetch (bash login)            | Info sistem saat login terminal                 |
| 7️⃣  | Install Docker                           | Instalasi lengkap Docker dan containerd         |
| 8️⃣  | Deploy Chromium via Docker               | Chromium headless berbasis `docker-compose`     |
| 0️⃣  | Keluar                                    | Menutup program                                  |

---

## 🧠 Info Sistem yang Ditampilkan

- Sistem Operasi
- CPU Core
- RAM Total
- Swap Total
- Disk Total (`/`)
- Disk Free (`/`)

---

## 📦 Cara Instalasi & Penggunaan

### 1. Unduh dan jalankan:

```bash
wget https://raw.githubusercontent.com/YoaTzy/setup-vps/main/vps-setup.sh -O vps-setup.sh
chmod +x vps-setup.sh
sudo ./vps-setup.sh
