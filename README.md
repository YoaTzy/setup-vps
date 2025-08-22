# 🚀 VPS Setup Assistant (All-in-One Script)

Script bash interaktif untuk konfigurasi awal VPS berbasis Linux (Ubuntu/Debian).  
Semua fitur ada dalam satu file — tanpa dependensi eksternal. Cocok untuk server AWS, DigitalOcean, Vultr, Linode, dan VPS lainnya.

## 💻 Persyaratan Sistem

- Sistem Operasi: Ubuntu 18.04+ atau Debian 10+
- Akses root atau sudo
- Koneksi internet aktif
- Minimal RAM: 512MB (rekomendasi: 1GB+)
- Minimal Disk: 5GB free space

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

### Metode 1: One-liner Command (Termudah)

```bash
bash <(curl -s https://raw.githubusercontent.com/YoaTzy/setup-vps/main/vps-setup.sh)
```

### Metode 2: Download & Jalankan

```bash
wget https://raw.githubusercontent.com/YoaTzy/setup-vps/main/vps-setup.sh -O vps-setup.sh
chmod +x vps-setup.sh
sudo ./vps-setup.sh
```

### Metode 3: Clone Repository

```bash
git clone https://github.com/YoaTzy/setup-vps.git
cd setup-vps
chmod +x vps-setup.sh
sudo ./vps-setup.sh
```

## 🔄 Update Script

Untuk mendapatkan versi terbaru script, jalankan:

```bash
wget https://raw.githubusercontent.com/YoaTzy/setup-vps/main/vps-setup.sh -O vps-setup.sh --no-check-certificate
chmod +x vps-setup.sh
```

## 🛠️ Troubleshooting

- **Jika terjadi error "Permission denied"**: Pastikan script memiliki izin eksekusi dengan perintah `chmod +x vps-setup.sh`
- **Jika terjadi error pada menu Swap**: Pastikan ukuran swap yang dimasukkan valid (contoh: 2G atau 512M)
