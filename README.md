# 🚀 VPS Setup Assistant

Script bash interaktif **all-in-one** untuk setup awal server Linux (Ubuntu/Debian).  
Dirancang untuk **semua provider VPS** — tanpa deteksi khusus seperti AWS atau DigitalOcean.

---

## ✨ Fitur Utama

✅ Menampilkan informasi lengkap server  
✅ Konfigurasi SSH root dan port  
✅ Manajemen swap RAM  
✅ Install tool penting: Speedtest, vnStat, neofetch  
✅ Menu interaktif, mudah digunakan

---

## 🖥️ Informasi Server yang Ditampilkan

- Sistem Operasi (OS)
- Jumlah CPU Core
- Total RAM
- Total Swap
- Total Disk (mount point `/`)

---

## 📋 Menu yang Tersedia

| No | Fitur | Keterangan |
|----|-------|------------|
| 1️⃣ | Enable root login | Aktifkan login root via password |
| 2️⃣ | Ganti port SSH | Ubah port default `22` menjadi port custom |
| 3️⃣ | Swap Manager | Buat swap baru dengan ukuran dan swappiness sesuai input |
| 4️⃣ | Install Speedtest | CLI resmi dari Ookla |
| 5️⃣ | Install vnStat | Monitor penggunaan bandwidth jaringan |
| 6️⃣ | Install neofetch | Tampilkan info sistem otomatis saat login |
| 0️⃣ | Keluar | Tutup program |

---

## 🛠️ Cara Instalasi & Jalankan

```bash
wget https://raw.githubusercontent.com/YoaTzy/setup-vps/main/vps-setup.sh -O vps-setup.sh
chmod +x vps-setup.sh
sudo ./vps-setup.sh
