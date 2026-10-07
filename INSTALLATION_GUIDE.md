# Panduan Instalasi & Deployment - SehatKu HMS

Dokumentasi resmi instalasi dan konfigurasi sistem **SehatKu HMS (Hospital Management System)** untuk lingkungan Development (Lokal) maupun Production (Server/VPS).

---

## Daftar Isi
1. [Prasyarat Sistem](#1-prasyarat-sistem)
2. [Metode 1: Menjalankan Cepat dengan Docker (Rekomendasi)](#2-metode-1-menjalankan-cepat-dengan-docker-rekomendasi)
3. [Metode 2: Instalasi Manual (Lokal / VPS)](#3-metode-2-instalasi-manual-lokal--vps)
4. [Akun Uji Coba Default (Demo Credentials)](#4-akun-uji-coba-default-demo-credentials)
5. [Panduan Konfigurasi Produksi (Production VPS & Nginx)](#5-panduan-konfigurasi-produksi-production-vps--nginx)
6. [Troubleshooting & Solusi Masalah Umum](#6-troubleshooting--solusi-masalah-umum)

---

## 1. Prasyarat Sistem

### Kebutuhan Perangkat Lunak:
- **Node.js**: Versi `18.x` atau `20.x` LTS
- **PostgreSQL**: Versi `15.x` atau `16.x`
- **Redis**: Versi `7.x` (Opsional untuk caching)
- **Flutter SDK**: Versi `>= 3.22.x` (Channel Stable)
- **Docker & Docker Compose**: (Jika menggunakan deployment container)
- **Google Chrome**: (Untuk akses frontend web)

---

## 2. Metode 1: Menjalankan Cepat dengan Docker (Rekomendasi)

Jika Anda sudah memiliki Docker terpasang di komputer/server, Anda dapat menjalankan database dan seluruh backend hanya dengan 1 perintah:

### Langkah 1: Jalankan Docker Compose
```bash
# Buka terminal di folder root sehatku_hms
docker compose up -d --build
```

Layanan yang otomatis aktif:
- **Backend REST API**: `http://localhost:3000/api/v1`
- **Swagger API Documentation**: `http://localhost:3000/api/docs`
- **PostgreSQL Database**: `localhost:5432` (Database: `sehatku_hms_db`)
- **pgAdmin 4 (Web Database GUI)**: `http://localhost:5050`
  - *Email*: `admin@sehatku.id` | *Password*: `admin_password_2026`

### Langkah 2: Jalankan Frontend Flutter Web
```bash
cd sehatku_hms_mobile
flutter pub get
flutter run -d chrome --web-port=8080
```

Aplikasi web klinik akan langsung terbuka di browser Anda pada alamat `http://localhost:8080`.

---

## 3. Metode 2: Instalasi Manual (Lokal / VPS)

### A. Persiapan Database PostgreSQL
1. Buat database baru bernama `sehatku_hms_db` di PostgreSQL Anda:
```sql
CREATE DATABASE sehatku_hms_db;
```

### B. Konfigurasi & Menjalankan Backend (NestJS)
1. Masuk ke direktori backend:
```bash
cd sehatku_hms_backend
```

2. Salin environment template:
```bash
cp .env.example .env
```
> Sesuaikan `DATABASE_URL` pada file `.env` jika username/password database PostgreSQL Anda berbeda.

3. Install dependensi dan sinkronkan database:
```bash
npm install
npx prisma generate
npx prisma db push
npm run prisma:seed
```

4. Jalankan backend:
```bash
# Mode Development (Auto-reload saat edit kode)
npm run dev

# Atau Mode Production (Build dist)
npm run build
npm run start:prod
```
*Backend API aktif di `http://localhost:3000/api/v1`*

### C. Menjalankan Frontend Flutter (Web & Mobile)
1. Masuk ke direktori frontend:
```bash
cd ../sehatku_hms_mobile
```

2. Unduh dependensi:
```bash
flutter pub get
```

3. Jalankan sesuai target platform:
```bash
# 1. Jalankan di Browser Chrome
flutter run -d chrome

# 2. Jalankan di Android Emulator / Device Fisik
flutter run -d android

# 3. Jalankan di macOS Desktop
flutter run -d macos
```

#### Opsi Parameter Kustom (`--dart-define`):
Jika backend Anda di-host di server/domain lain, gunakan parameter:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://api-klinik-anda.com/api/v1
```

---

## 4. Akun Uji Coba Default (Demo Credentials)

Database seed telah dilengkapi akun uji coba dengan hak akses multi-role:

| Role Pengguna | Email | Password | Hak Akses Utama |
| :--- | :--- | :--- | :--- |
| **Hospital Administrator** | `admin@sehatku.id` | `password123` | Akses penuh seluruh tab admin, pendaftaran pasien walk-in, antrean, kasir POS & shift closing, etiket farmasi, ranap, lab, export laporan Dinkes. |
| **Dokter Spesialis (dr. Maya)** | `doctor@sehatku.id` | `password123` | Antrean poli, rekam medis SOAP, TTV, ICD-10, resep obat, penerbitan Surat Izin Sakit (SKD) & Surat Sehat ber-QR Code. |
| **Pasien Terdaftar** | `patient@sehatku.id` | `password123` | Portal booking konsultasi dokter, cek nomor antrean live, download kwitansi bayar dan riwayat medis. |

---

## 5. Panduan Konfigurasi Produksi (Production VPS & Nginx)

Untuk deployment di server Cloud / VPS Ubuntu (misal DigitalOcean, AWS EC2, Biznet GIO, Niagahoster):

### 1. Reverse Proxy Nginx Configuration (`/etc/nginx/sites-available/sehatku.conf`)
```nginx
# Backend API & WebSocket
server {
    server_name api.klinikanda.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Frontend Flutter Web Build
server {
    server_name app.klinikanda.com;
    root /var/www/sehatku_web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 2. Build Frontend untuk Web Hosting
```bash
cd sehatku_hms_mobile
flutter build web --release --dart-define=API_BASE_URL=https://api.klinikanda.com/api/v1
# Salin seluruh isi folder build/web ke /var/www/sehatku_web di server Anda.
```

---

## 6. Troubleshooting & Solusi Masalah Umum

### Q1: Suara antrean speaker tidak berbunyi di Chrome?
- **Penyebab:** Kebijakan browser Google Chrome memblokir audio otomatis (*Autoplay Policy*) sebelum pengguna berinteraksi pertama kali dengan halaman.
- **Solusi:** Klik sekali di area layar TV Antrean (`/queue-display`), maka suara ding-dong dan panggilan TTS akan aktif normal.

### Q2: Error CORS (*Cross-Origin Resource Sharing*) saat memanggil API dari Web?
- **Solusi:** Backend SehatKu HMS sudah dilengkapi CORS wildcard untuk development. Jika menggunakan domain production khusus, atur allowed origin di `src/main.ts`.

### Q3: Foto dokter / avatar tidak tampil di Android Emulator?
- **Solusi:** Android Emulator menganggap `localhost` adalah emulator itu sendiri. Sistem SehatKu secara otomatis meremapping URL asset ke `10.0.2.2:3000` khusus pada target Android.
