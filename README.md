# 🚀 VPS Setup Assistant - All-in-One Bash Script

Script bash interaktif untuk mengelola konfigurasi dasar server Linux seperti:
- Enable root login via password
- Mengganti port SSH
- Mengelola swap RAM

💡 Cocok untuk semua provider VPS (AWS, DigitalOcean, Vultr, dsb) dengan sistem operasi **Ubuntu/Debian**.

---

## ✨ Fitur

- ✅ Deteksi otomatis OS & provider VPS
- ✅ Menu CLI interaktif (user-friendly)
- ✅ Tidak butuh file eksternal (semua dalam 1 script)
- ✅ Swap RAM Manager custom (dengan swappiness)
- ✅ Konfigurasi SSH & Firewall otomatis

---

## 📦 Instalasi & Jalankan

```bash
wget https://raw.githubusercontent.com/YoaTzy/setup-vps/refs/heads/main/vps-setup.sh -O vps-setup.sh
chmod +x vps-setup.sh
sudo ./vps-setup.sh
