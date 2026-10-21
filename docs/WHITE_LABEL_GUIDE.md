# Panduan White-labeling & Kustomisasi Branding - SehatKu HMS

Panduan komprehensif bagi pembeli source code atau tim implementasi untuk mengubah identitas merek (*re-branding* / *white-labeling*) sistem SehatKu HMS menjadi nama klinik, puskesmas, atau rumah sakit Anda sendiri.

---

## Daftar Isi
1. [Ringkasan Komponen Branding](#1-ringkasan-komponen-branding)
2. [Kustomisasi Identitas di Backend (Database & API)](#2-kustomisasi-identitas-di-backend-database--api)
3. [Kustomisasi Tampilan & Tema Warna Frontend (Flutter)](#3-kustomisasi-tampilan--tema-warna-frontend-flutter)
4. [Kustomisasi Kop Surat Resmi & Dokumen Cetak HTML](#4-kustomisasi-kop-surat-resmi--dokumen-cetak-html)
5. [Penggantian Aset Logo, Favicon & Ikon Aplikasi](#5-penggantian-aset-logo-favicon--ikon-aplikasi)
6. [Konfigurasi Nilai Default & Environment Produksi](#6-konfigurasi-nilai-default--environment-produksi)

---

## 1. Ringkasan Komponen Branding

Sistem SehatKu HMS dirancang modular sehingga memudahkan kustomisasi identitas tanpa perlu merombak logika bisnis inti. Komponen yang dapat disesuaikan meliputi:
- **Nama Instansi Kesehatan**: Nama resmi klinik atau rumah sakit.
- **Identitas Legalitas**: Nomor Izin Operasional RS, SK Kemenkes, NPWP, dan SIP dokter.
- **Kop Surat Cetak**: Header dokumen Surat Sakit, Resume Medis Ranap, dan Kuitansi Kasir.
- **Palet Warna Merek**: Warna primer (*primary color*), warna aksen, dan gradien tombol.
- **Aset Grafis**: Logo rumah sakit, favicon tab peramban web, dan ikon instalasi aplikasi mobile.

---

## 2. Kustomisasi Identitas di Backend (Database & API)

Data institusi kesehatan tersimpan pada tabel `hospitals` di database PostgreSQL.

### A. Memperbarui Data Institusi pada Database Seed
Buka berkas [seed.ts](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_backend/prisma/seed.ts) dan sesuaikan objek hospital:

```typescript
const hospital = await prisma.hospital.upsert({
  where: { code: 'HOSP-SEHATKU-001' },
  update: {},
  create: {
    id: '00000001-0000-4000-8000-000000000001',
    code: 'HOSP-KLINIK-001', // Sesuaikan kode faskes
    name: 'RS Pratama Sejahtera', // Ganti dengan nama RS Anda
    address: 'Jl. Pemuda No. 45, Surabaya, Jawa Timur',
    phone: '(031) 555-1234',
    email: 'info@rspratamasejahtera.co.id',
    website: 'https://rspratamasejahtera.co.id',
    timezone: 'Asia/Jakarta',
    status: 'active',
  },
});
```

Jika Anda menggunakan skrip SQL langsung, perbarui baris `INSERT INTO hospitals` di [seed.sql](file:///Users/macbookpro/development/sehatku_hms/database/seed.sql).

### B. Konfigurasi Variabel Lingkungan Backend
Pada berkas `.env` di folder backend, sesuaikan nama default instansi jika diperlukan:
```env
DEFAULT_HOSPITAL_ID=00000001-0000-4000-8000-000000000001
HOSPITAL_NAME="RS Pratama Sejahtera"
```

---

## 3. Kustomisasi Tampilan & Tema Warna Frontend (Flutter)

Seluruh tema warna diatur terpusat di modul core Flutter sehingga Anda cukup mengubah token warna di satu tempat.

### A. Mengubah Palet Warna (Theme Tokens)
Buka berkas [app_theme.dart](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_mobile/lib/core/theme/app_theme.dart) dan [app_colors.dart](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_mobile/lib/core/theme/app_colors.dart):

```dart
class AppTheme {
  // Warna Utama (Ubah sesuai corporate identity RS Anda)
  static const Color primary = Color(0xFF0F766E); // Default: Teal / Biru Medis
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFFCCFBF1);

  // Warna Sekunder / App Bar Navy
  static const Color navy = Color(0xFF0F172A); // Default: Slate Dark Navy
  
  // Warna Aksen / Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}
```

### B. Mengubah Nama Aplikasi di Peramban & Mobile
1. **Web Title:** Buka berkas [index.html](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_mobile/web/index.html) dan perbarui tag `<title>`:
   ```html
   <title>RS Pratama Sejahtera - Hospital Management System</title>
   ```
2. **Android App Name:** Buka berkas `android/app/src/main/AndroidManifest.xml`, cari atribut `android:label`:
   ```xml
   android:label="RS Sejahtera HMS"
   ```
3. **iOS App Name:** Buka berkas `ios/Runner/Info.plist`, cari key `CFBundleDisplayName`:
   ```xml
   <key>CFBundleDisplayName</key>
   <string>RS Sejahtera</string>
   ```

---

## 4. Kustomisasi Kop Surat Resmi & Dokumen Cetak HTML

Sistem SehatKu HMS dilengkapi generator dokumen HTML beresolusi tinggi untuk dicetak ke PDF atau printer fisik.

Buka berkas [document_template_helper.dart](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_mobile/lib/core/utils/document_template_helper.dart).

### A. Mengubah Kop Surat Rumah Sakit (Header Kop)
Cari konstanta atau method header kop surat di `DocumentTemplateHelper`:

```dart
static String buildHospitalHeader({
  String hospitalName = 'RUMAH SAKIT PRATAMA SEJAHTERA',
  String hospitalTagline = 'Layanan Medis Cepat, Terpercaya, dan Terakreditasi Paripurna',
  String hospitalAddress = 'Jl. Pemuda No. 45, Surabaya • Telp: (031) 555-1234 • Email: kontak@rspratama.id',
  String operationalLicense = 'Izin Operasional RS No. 445/102/IO-RS/2023',
}) {
  return '''
    <div style="text-align: center; border-bottom: 2px solid #0f172a; padding-bottom: 12px; margin-bottom: 20px;">
      <h2 style="margin: 0; font-size: 20px; font-weight: 800; color: #0f172a; letter-spacing: 0.5px;">$hospitalName</h2>
      <p style="margin: 3px 0; font-size: 11px; font-style: italic; color: #0d9488;">$hospitalTagline</p>
      <p style="margin: 2px 0; font-size: 11px; color: #334155;">$hospitalAddress</p>
      <p style="margin: 2px 0; font-size: 10px; color: #64748b;">$operationalLicense</p>
    </div>
  ''';
}
```

### B. Mengubah Footer & Tanda Tangan Kuitansi Kasir
Pada template Kuitansi Pembayaran di method `buildOfficialReceiptHtml`, sesuaikan teks stempel kasir dan catatan legalitas:
```html
<div class="receipt-note">
  <p>Bukti pembayaran ini adalah dokumen sah yang diterbitkan oleh Kasir Sistem Keuangan RS Pratama Sejahtera.</p>
</div>
```

---

## 5. Penggantian Aset Logo, Favicon & Ikon Aplikasi

1. **Logo Web & Login Header:**
   - Letakkan berkas logo berlatar transparan (format PNG/SVG) di folder `sehatku_hms_mobile/assets/images/logo_hospital.png`.
   - Resolusi optimal: `512x512` piksel (ikon kotak) dan `600x150` piksel (logo horizontal).
2. **Favicon Browser:**
   - Ganti berkas `sehatku_hms_mobile/web/favicon.png` dengan logo mini ukuran `32x32` atau `64x64` piksel.
3. **Ikon Mobile (App Icon):**
   - Jalankan plugin `flutter_launcher_icons` setelah memperbarui logo di folder `assets/`.

---

## 6. Konfigurasi Nilai Default & Environment Produksi

### A. Menghubungkan Frontend ke Domain Server Produksi
Buka berkas [app_env.dart](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_mobile/lib/core/config/app_env.dart):
```dart
class AppEnv {
  // Ganti localhost dengan domain backend produksi atau IP VPS Anda
  static const String defaultBaseUrl = 'https://api-hms.rspratamasejahtera.co.id';
}
```
Atau berikan environment parameter saat melakukan build:
```bash
flutter build web --release --dart-define=API_URL=https://api-hms.rspratamasejahtera.co.id
```

### B. Format Mata Uang & Penomoran Dokumen
- Format mata uang Rupiah secara default telah menggunakan standar perbankan Indonesia (`Rp 150.000,00`) di [currency_formatter.dart](file:///Users/macbookpro/development/sehatku_hms/sehatku_hms_mobile/lib/core/utils/currency_formatter.dart).
- Prefix nomor registrasi dapat diubah di konfigurasi backend:
  - Antrean Poli: `A-001`, `B-001`, `C-001`
  - Rekam Medis: `MRN-2026-XXXX`
  - Admisi Rawat Inap: `ADM-2026-XXXX`
  - Kuitansi Kasir: `INV-2026-XXXX`
  - Surat Keterangan Sakit: `SKS-2026-XXXX`
