# SehatKu HMS - Sistem Informasi Manajemen Rumah Sakit & Klinik Terpadu
**Enterprise Hospital & Clinic Management System (Full Source Code Package)**

> **Solusi Sistem Informasi Manajemen Klinik & Rumah Sakit Modern, Terpadu, dan Siap Pakai.**  
> Dibangun dengan arsitektur modern berstandar enterprise: **NestJS (TypeScript)**, **Prisma ORM**, **PostgreSQL**, dan **Flutter (Web & Mobile)**.

---

## Mengapa Memilih Source Code SehatKu HMS?

1. **Siap Pakai untuk Standar Operasional Indonesia**:
   - Dilengkapi pelafalan suara antrean bahasa Indonesia (*Indonesian TTS*) + nada bel ding-dong rumah sakit.
   - Rekam Medis Elektronik (RME) berstandar SOAP dan kode diagnosa ICD-10 Kemenkes RI.
   - Farmasi dengan cetak etiket obat minum (putih) & luar (biru) standar apotek.
   - Laporan 10 Besar Penyakit (LB1) yang siap di-export ke format spreadsheet Dinas Kesehatan.
2. **Multi-Role & Akses Hak Pengguna Terpadu (RBAC)**:
   - Akses terpisah untuk Administrator, Dokter Spesialis/Umum, Kasir, Apoteker, Resepsionis, dan Pasien.
3. **Multi-Platform Cross-Device**:
   - Dapat diakses via Browser Web (Komputer Loket/Dokter), Smart TV (Layar Antrean Ruang Tunggu), Tablet, maupun Smartphone (Android/iOS).
4. **Clean Code & Modular Architecture**:
   - Backend modular NestJS, fully typed Prisma ORM, Swagger/OpenAPI docs, dan Postman Collection lengkap.

---

## Rincian Modul & Fitur Lengkap

### 1.  Loket Pendaftaran & Admisi Pasien
- **Pencarian Live Cepat**: Temukan rekam medis pasien terdaftar via Nama, No. RM, NIK, No. HP, atau Asuransi.
- **Pendaftaran Pasien Baru (*Walk-In*)**: Form kilat untuk pasien baru yang langsung membuatkan No. RM otomatis.
- **Pilihan Poli & Dokter Spesialis**: Pilihan dokter dengan ketersediaan hari ini, kuota pasien, dan rating.
- **Karcis Antrean Visual**: Cetak karcis antrean langsung ke printer thermal 58mm.

### 2.  Sistem Antrean Suara & Layar TV Ruang Tunggu (`/queue-display`)
- **Panggilan Suara Otomatis (Indonesian TTS)**: Mengucapkan nomor antrean, nama pasien, nama poli, dan ruang dokter.
- **Bel Ding-Dong 2-Tone**: Suara synthesizer harmonis sebelum panggilan dimulai.
- **Layar TV Display Pintar**:
  - *Hero Card* panggilan aktif dengan highlight animasi.
  - Jam WIB real-time & Pengumuman Teks Berjalan (*Running Text*).
  - Sub-Counter antrean Poli Dokter, Kasir, dan Farmasi.

### 3.  Rekam Medis Elektronik (RME SOAP Dokter)
- **Subjective (Anamnesis)**: Keluhan utama dan riwayat penyakit pasien.
- **Objective (Pemeriksaan Fisik & TTV)**: Tekanan Darah, Nadi, Laju Nafas, Suhu, SpO2, TB, BB, dan kalkulasi BMI otomatis.
- **Assessment (Diagnosa ICD-10)**: Pencarian kode dan deskripsi diagnosa ICD-10.
- **Plan (Tindakan & E-Resep)**: Input tindakan medis berbayar dan peresepan obat langsung ke instalasi farmasi.
- **Surat Keterangan Dokter (SKD)**: Penerbitan Surat Izin Sakit dan Surat Keterangan Sehat dengan Kop Resmi, QR Code verifikasi, dan unduh PDF.

### 4.  Modul Farmasi & Etiket Stiker Obat
- **Alur Dispensing Resep**: *Menunggu* $\rightarrow$ *Sedang Diracik* $\rightarrow$ *Siap di Loket* $\rightarrow$ *Diserahkan ke Pasien*.
- **Cetak Etiket Stiker Obat Thermal (58mm/80mm)**:
  - **Etiket Putih (Obat Minum)**: Aturan pakai (Pagi/Siang/Malam, Sebelum/Sesudah Makan), nama obat, dosis, dan peringatan antibiotik.
  - **Etiket Biru (Obat Luar)**: Header "OBAT LUAR - TIDAK BOLEH DITELAN".
  - **Label Stiker RM (MRN Label)**: Untuk map berkas fisik pasien & tabung lab.
- **Otomatisasi Stok**: Stok obat otomatis berkurang seketika saat obat diserahkan.

### 5.  Kasir POS, Manajemen Shift, & Kwitansi Resmi
- **Buka & Tutup Shift Kasir**: Input modal kas awal laci dan rekonsiliasi uang fisik saat *closing shift* (kalkulasi surplus/defisit otomatis).
- **Multi-Metode Pembayaran**: Tunai, QRIS Dinamis, Transfer Bank, Kartu Debit/EDC, dan BPJS Kesehatan.
- **Cetak Kwitansi Resmi PDF**: Kwitansi ber-kop klinik dengan barcode/QR validasi keaslian.

### 6.  Modul Rawat Inap (Ranap) & Manajemen Kamar / Bed
- **Visual Bed Floor Plan**: Denah kamar interaktif (VIP, Kelas 1, 2, 3, ICU, Isolasi) dengan status *Tersedia, Terisi, Sterilisasi/Cleaning, Maintenance*.
- **Indikator Okupansi (BOR)**: Kalkulasi Bed Occupancy Rate otomatis.
- **Lembar CPPT**: Catatan Perkembangan Pasien Terintegrasi (SOAP visit harian dokter & perawat).
- **Transfer Bed & Discharge**: Pemindahan bed dan pemulangan pasien dengan kalkulasi lama hari rawat x tarif kamar otomatis ke kasir.

### 7.  Modul Laboratorium Terpadu (LIS)
- **Katalog Uji Lab**: Hematologi, kimia darah, urinalisis, serologi, radiologi dengan nilai rujukan normal & satuan.
- **Flagging Otomatis**: Indikator otomatis untuk hasil *Normal, Low, High, Critical*.
- **Cetak Hasil Lab A4**: Lembar hasil ber-kop klinik dengan verifikasi penanggung jawab Sp.PK.

### 8.  Laporan Analisis & Export Excel / CSV
- **Laporan LB1 Dinkes**: Rekapitulasi 10 Besar Penyakit dan agregasi gender pasien.
- **Laporan Keuangan & Kasir**: Download omzet dan rincian transaksi per metode bayar.
- **Laporan Stok & Valuasi Farmasi**: Mutasi stok, nomor batch, nilai aset persediaan obat.

---

## Spesifikasi Teknologi (Tech Stack)

| Komponen | Teknologi |
| :--- | :--- |
| **Backend Framework** | NestJS (TypeScript) |
| **Database & ORM** | PostgreSQL 16 + Prisma ORM 5.x |
| **Cache & Queue** | Redis 7 |
| **Frontend Mobile & Web** | Flutter 3.22+ (Dart) with Riverpod State Management |
| **Otentikasi & Keamanan** | JWT, Bcrypt, RBAC Guards, Immutable Audit Trail |
| **Dokumentasi API** | OpenAPI 3.1 (Swagger UI) + Postman Collection |
| **Containerization** | Docker & Docker Compose |

---

## Nilai Komersial & Ide Bisnis untuk Pembeli
Source code ini dapat Anda manfaatkan untuk:
1. **Dijual ke Klien Klinik/Praktek Mandiri**: Jual sebagai paket software SIMKlinik siap pasang seharga puluhan juta rupiah.
2. **Bisnis SaaS SIMKlinik Cloud**: Sewakan sistem ke banyak klinik dengan biaya berlangganan bulanan.
3. **Portofolio & Base Code Software House**: Hemat ratusan jam waktu pengembangan untuk proyek software kesehatan.
