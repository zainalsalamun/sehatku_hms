# SehatKu HMS Frontend (Flutter Mobile & Web)

Aplikasi klien lintas platform untuk SehatKu Hospital Management System, dibangun menggunakan Flutter 3.x dan Riverpod. Aplikasi ini mendukung tampilan responsif untuk Mobile (Android/iOS) serta Web / Desktop Dashboard (Admin, Dokter & Kasir).

---

## 1. Tech Stack & Arsitektur Frontend

- Framework: Flutter 3.x (Dart 3.x)
- State Management: Riverpod 2.x (NotifierProvider, StateNotifierProvider)
- HTTP Client: Dio dengan interceptor JWT token otomatis
- Routing: MaterialPageRoute & Indexed Navigation Hubs
- Internationalization & Format: intl (Format Rupiah & Tanggal Indonesia)
- Design System: Material Design 3 dengan palet warna klinis (Navy #0B2B3E & Teal #0D9488)

---

## 2. Struktur Direktori Frontend (lib/)

```text
lib/
├── main.dart                  # Entry point aplikasi & ProviderScope
├── core/
│   ├── network/               # DioClient, HmsApiClient, API Contracts
│   ├── providers/             # Global riverpod providers (apiClientProvider)
│   └── theme/                 # AppTheme (Typography, Colors, Shapes, Tokens)
├── shared/
│   ├── models/                # Data Models (Doctor, Patient, Appointment, Invoice, MedicalRecord)
│   └── widgets/               # Shared Widgets (SectionHeader, MetricCard, OfficialReceiptDialog)
└── features/
    ├── authentication/        # Login Screen, Role Selector & AuthController
    ├── patient/               # Portal Pasien: Home, Janji Temu, Layanan, Profil & Ticket Dialog
    ├── doctor/                # Dashboard Dokter, Live Queue, EMR SOAP Form, ICD-10 Dialog
    ├── pharmacy/              # Dispensing Tracker, Restock Modal, Riverpod Providers
    ├── medical_record/        # Rekam Medis Pasien Screen & MedicalRecordsNotifier
    ├── appointment/           # Interactive Booking Sheet & Payment Checkout
    └── admin/                 # Dashboard Admin (Overview, Dokter, Pasien, Antrean, Kasir, Audit)
```

---

## 3. Panduan Menjalankan Frontend

### Prasyarat
- Flutter SDK >= 3.22.x terpasang di sistem (flutter doctor centang hijau).
- Backend SehatKu HMS sudah aktif di http://localhost:3000.

### Instalasi Dependensi
Masuk ke folder sehatku_hms_mobile:
```bash
cd sehatku_hms_mobile
flutter pub get
```

---

### Menjalankan di Browser Google Chrome (Flutter Web)
Rekomendasi untuk menguji seluruh modul: Portal Pasien, Layar TV Antrean (/queue-display), Dashboard Dokter, Kasir POS, dan Dashboard Admin:

```bash
# 1. Jalankan langsung di Google Chrome (Default)
flutter run -d chrome

# 2. Jalankan dengan port spesifik (misal port 8080)
flutter run -d chrome --web-port=8080

# 3. Jalankan dengan API Base URL kustom (opsional)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# 4. Mode Web Server (akses manual via http://localhost:8080)
flutter run -d web-server --web-port 8080
```

#### Pintasan Terminal Interaktif:
- **`r`** : Hot Reload (UI langsung berubah seketika).
- **`R`** : Hot Restart (Mulai ulang state aplikasi).
- **`q`** : Menghentikan debug server.

---

### Menjalankan di Mobile (Android / iOS)
Rekomendasi untuk menguji Portal Pasien (Booking, Tiket Antrean & Kwitansi):

```bash
# Periksa perangkat / emulator yang tersedia
flutter devices

# Jalankan pada target emulator yang dipilih
flutter run -d <device_id>
```

---

## 4. Alur Kerja per Peran Pengguna

### Role: Pasien
- Beranda Pasien: Menampilkan salam personal, kartu antrean aktif, dan tombol akses cepat.
- Booking & Pembayaran: Memilih dokter, slot waktu, input keluhan, dan checkout simulasi QRIS.
- Tab Janji Temu: Filter status reservasi (Aktif, Selesai, Dibatalkan), membuka barcode tiket antrean, dan cetak kwitansi.
- Tab Rekam Medis: Riwayat kunjungan klinis lengkap dengan tanda vital, diagnosa ICD-10, dan resep obat.

### Role: Dokter Spesialis
- Dashboard Antrean Live: Counter antrean real-time per dokter spesialis.
- Pemeriksaan EMR SOAP:
  - Input anamnesis pasien.
  - Input tanda vital (kalkulasi BMI otomatis).
  - Pencarian katalog resmi ICD-10.
  - Peresepan obat formularium rumah sakit.
  - Tanda tangan rekam medis dan otomatis meneruskan resep ke Farmasi.

### Role: Hospital Admin / Kasir / Apoteker
- Overview Operasional: Metrik pasien, dokter aktif, antrean, dan pendapatan lunas.
- Kasir POS & Invoice: Pelunasan multi-metode (Tunai, QRIS, Kartu Debit, BPJS) dan generator Kwitansi Resmi PDF.
- Farmasi & Apotek: Dispensing tracker (Menunggu -> Diracik -> Siap di Loket -> Selesai) dan manajemen stok obat.
- Audit Trail: Pemantauan log mutasi data immutable.

---

## 5. Akun Uji Coba Default

| Peran | Email | Password |
| :--- | :--- | :--- |
| Hospital Admin | admin@sehatku.id | password123 |
| Dokter Spesialis | doctor@sehatku.id | password123 |
| Pasien | patient@sehatku.id | password123 |
