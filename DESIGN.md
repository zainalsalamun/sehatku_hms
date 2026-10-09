# SehatKu HMS Design System and UI Specification

Dokumen standar desain antarmuka, palet warna, tipografi, tata letak, dan komponen untuk seluruh ekosistem SehatKu Hospital Management System (HMS). Standar ini wajib dipatuhi oleh modul front-end (Flutter Mobile, Tablet, dan Web) untuk menjamin konsistensi visual, kejelasan informasi klinis, aksesibilitas, dan keandalan sistem.

---

## 1. Prinsip Utama Desain (Core Design Principles)

1. **Kejelasan Klinis (Clinical Clarity)**
   Informasi medis, nomor rekam medis (MRN), dosis obat, status pembayaran, dan antrean pasien harus memiliki kontras tinggi, keterbacaan instan, dan bebas dari ambiguitas visual.

2. **Pencegahan Kesalahan Pengguna (Error-Prevention UX)**
   Tindakan medis kritis seperti pembatalan reservasi, penghapusan data pasien, peracikan obat farmasi, dan penutupan shift kasir harus memiliki dialog konfirmasi, validasi formulir berlapis, dan umpan balik yang jelas.

3. **Tata Letak Responsif Bebas Overflow (Zero-Overflow Responsive Layouts)**
   Semua formulir, dialog, dan tabel data harus dapat menyesuaikan ukuran layar dari perangkat genggam (ponsel), tablet perawat, hingga layar lebar monitor administrasi tanpa memicu RenderFlex overflow.

4. **Keberlanjutan & Modularitas (Design Token Modularity)**
   Semua warna, radius sudut, ketebalan border, dan tipografi didefinisikan melalui token terpusat (`AppColors` dan `AppTheme`) tanpa nilai heksadesimal acak di tingkat widget.

---

## 2. Palet Warna dan Token Semantik (Color Tokens)

### 2.1. Warna Identitas Utama (Brand Colors)

| Nama Token | Kode HEX | Peruntukan / Penggunaan |
| :--- | :--- | :--- |
| `AppColors.primary` | `#087F8C` | Warna brand utama, tombol primer, tab aktif, icon header. |
| `AppColors.primaryDark` | `#055E68` | State hover / pressed tombol primer, header panel gelap. |
| `AppColors.primaryLight` | `#E0F2F1` | Background chip aktif, container highlight, avatar background. |
| `AppColors.secondary` | `#63C7B2` | Aksen sekunder, indikator proses, badge pendukung. |

### 2.2. Warna Netral dan Latar Belakang (Neutrals & Surfaces)

| Nama Token | Kode HEX | Peruntukan / Penggunaan |
| :--- | :--- | :--- |
| `AppColors.navy` | `#123047` | Judul utama, header tabel, tombol aksi khusus (TV Antrean). |
| `AppColors.navyDark` | `#0D2131` | Sidebar background, teks kontras tertinggi. |
| `AppColors.background` | `#F5F8FA` | Latar belakang seluruh halaman/scaffold aplikasi. |
| `AppColors.surface` | `#FFFFFF` | Latar belakang kartu (Card), dialog modal, input form. |
| `AppColors.cardBorder` | `#E4EBEF` | Garis batas kartu, pemisah baris tabel, border input aktif. |

### 2.3. Tipografi Warna Teks (Text Colors)

| Nama Token | Kode HEX | Peruntukan / Penggunaan |
| :--- | :--- | :--- |
| `AppColors.textPrimary` | `#123047` | Teks judul, nama pasien, nama dokter, nilai metrik utama. |
| `AppColors.textSecondary` | `#405667` | Teks deskripsi, label input, isi tabel biasa. |
| `AppColors.textMuted` | `#607585` | Teks sekunder, timestamp, petunjuk input (helper/hint). |
| `AppColors.textWhite` | `#FFFFFF` | Teks di atas tombol primer atau background gelap. |

### 2.4. Status Semantik Klinis & Finansial (Status Badges)

| Status Klinis | Background | Border | Teks | Penggunaan |
| :--- | :--- | :--- | :--- | :--- |
| **Success** | `#E8F5E9` | `#A5D6A7` | `#1B5E20` | Status Lunas, Selesai, Bed Tersedia, Terverifikasi |
| **Warning** | `#FFF8E1` | `#FFE082` | `#E65100` | Status Menunggu, Antrean Terbit, Stok Menipis |
| **Info / In-Progress** | `#E1F5FE` | `#90CAF9` | `#0D47A1` | Checked-in, Sedang Diracik, Poli BPJS, Konsultasi |
| **Danger / Error** | `#FBF0F1` | `#E5A8AF` | `#6B111A` | Dibatalkan, Stok Kritis, Tagihan Tertunda, CITO |

### 2.5. Aksen Warna Modul Fungsional RS (Hospital Module Accents)

| Modul Rumah Sakit | Aksen Utama | Latar Belakang Tint | Border Kontainer |
| :--- | :--- | :--- | :--- |
| **Poli Kardiologi / DPJP** | Indigo (`#4F46E5`) | `#EEF2FF` | `#C7D2FE` |
| **Farmasi / Apotek** | Violet (`#7E22CE`) | `#F3E8FF` | `#D8B4FE` |
| **Laboratorium & Diagnostik** | Teal (`#0D9488`) | `#CCFBF1` | `#99F6E4` |
| **Kasir & Billing POS** | Emerald (`#059669`) | `#ECFDF5` | `#A7F3D0` |
| **Rawat Inap & Bed Management** | Sky Blue (`#0284C7`) | `#E0F2FE` | `#BAE6FD` |

---

## 3. Sistem Tipografi (Typography Scale)

Sistem menggunakan font utama keluarga **SF Pro Display** (dengan fallback **Roboto** / **Inter** / Sans-Serif).

| Gaya Teks | Ukuran (sp) | Bobot (FontWeight) | Line Height | Penggunaan |
| :--- | :--- | :--- | :--- | :--- |
| **Display / Page Title** | 24 - 28 | `FontWeight.w800` (Bold) | 1.2 | Judul tab admin, nama modul utama |
| **Section Title (TitleLarge)** | 18 - 20 | `FontWeight.w700` (Bold) | 1.3 | Judul kartu, header modal dialog |
| **Card Title (TitleMedium)** | 15 - 16 | `FontWeight.w600` (SemiBold) | 1.4 | Nama pasien di list, subjudul bagian |
| **Body Primary** | 13 - 14 | `FontWeight.w400` (Regular) | 1.5 | Isi teks utama, nilai data tabel |
| **Body Bold** | 13 - 14 | `FontWeight.w600` (SemiBold) | 1.5 | Label kolom, nomor antrean, nominal harga |
| **Caption / Helper** | 11 - 12 | `FontWeight.w400` (Regular) | 1.4 | Helper text input, timestamp audit |
| **Badge / Overline** | 10 - 11 | `FontWeight.w700` (Bold) | 1.0 | Status chip, tag penjamin, kategori |

### Aturan Khusus Format Teks:
1. **Nomor Antrean:** Menggunakan format kapital tegas dengan pemisah strip (contoh: `A-001`, `B-012`, `K-104`, `F-003`).
2. **Mata Uang Rupiah:** Wajib menggunakan format standar Bank Indonesia (contoh: `Rp 350.000`, tanpa desimal sen untuk nominal bulat).
3. **Tanggal dan Waktu:** Menggunakan format 24 jam dengan zona waktu Indonesia (contoh: `08/10/2026 10:30 WIB`).
4. **Nomor Rekam Medis (MRN):** Format baku `MRN-YYYY-XXX` (contoh: `MRN-2026-001`).

---

## 4. Sistem Grid, Jarak, dan Tata Letak Responsif

### 4.1. Skala Jarak Spasial (Spatial Spacing Grid)

Sistem menggunakan kelipatan basis 4pt / 8pt:
* `4px`: Jarak internal antar icon dan teks ringkas.
* `8px`: Margin antar chip, padding badge, jarak elemen inline.
* `12px`: Jarak vertikal antar input dalam form, gap grid kartu kecil.
* `16px`: Padding internal kartu standar, padding dialog di layar ponsel.
* `20px`: Padding kartu dashboard overview, gap antar modul besar.
* `24px`: Padding layar desktop, margin horizontal container utama.
* `32px`: Margin pembatas antar seksi utama.

### 4.2. Breakpoint Layar (Responsive Breakpoints)

| Breakpoint | Lebar Layar | Strategi Layout |
| :--- | :--- | :--- |
| **Mobile** | `< 600px` | 1 Kolom vertikal, dropdown *full-width*, dialog memenuhi layar (lebar 92-96%), padding 16px. |
| **Tablet** | `600px - 1000px` | 2 Kolom grid, dialog lebar 540-640px, padding 20px. |
| **Desktop / Admin** | `> 1000px` | 3 - 6 Kolom KPI grid, split panel 2 kolom, tabel data lebar penuh, padding 24px. |

### 4.3. Aturan Pencegahan RenderFlex Overflow:
1. **DropdownButtonFormField:**
   * Wajib menyertakan properti `isExpanded: true`.
   * Teks di dalam `DropdownMenuItem` wajib dibungkus dengan `Text(..., overflow: TextOverflow.ellipsis)`.
2. **Form Input dalam Row:**
   * Tidak diperbolehkan menaruh lebih dari 2 kontrol form yang dapat membesar dalam satu `Row` tanpa `LayoutBuilder`.
   * Kontrol input 3 kolom harus dipecah menjadi 2 baris seimbang di mode modal atau menggunakan `Wrap`.
3. **Tabel Data:**
   * Sel tabel teks panjang (nama pasien, nama obat, diagnosa) wajib dibungkus `Expanded` atau memiliki `maxLines: 1` dengan `TextOverflow.ellipsis`.

---

## 5. Standar Komponen UI (UI Components Specification)

### 5.1. Kartu Ringkasan Metrik (MetricCard)
* **Latar Belakang:** Putih murni (`#FFFFFF`).
* **Radius Sudut:** 16px (`BorderRadius.circular(16)`).
* **Border:** 1px solid `#E4EBEF`.
* **Elevasi:** 0 (Flat modern) dengan border pemisah.
* **Struktur:**
  * Kiri: Icon dalam kontainer bulat berbayang warna lembut (`alpha: 0.12`).
  * Kanan: Nilai angka tebal (22-26sp, `FontWeight.bold`), di bawahnya label deskripsi abu-abu (12sp).

### 5.2. Tabel Data Administrasi (AdminTableContainer)
* **Header Bar:**
  * Field pencarian terintegrasi di sisi kiri dengan icon search.
  * Dropdown filter status atau aksi export di sisi kanan.
* **Header Kolom:**
  * Background abu-abu terang netral (`#F8FAFC`).
  * Teks huruf kapital tebal (11sp, warna `#64748B`).
* **Baris Data (Row):**
  * Tinggi baris konsisten (52-60px per baris).
  * Efek zebra atau border bawah 1px `#F1F5F9`.
  * Efek hover lembut pada pointer kursor desktop.
* **Pagination Footer (AdminPaginationFooter):**
  * Menampilkan informasi baris: `Menampilkan X - Y dari Z data`.
  * Dropdown ukuran halaman (`10`, `25`, `50` data per halaman).
  * Tombol navigasi halaman aktif dengan indikator nomor halaman.

### 5.3. Kotak Input Formulir (Form Fields)
* **InputDecorationTheme:**
  * `filled: true`, `fillColor: Colors.white`.
  * `contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)`.
  * `border`: `OutlineInputBorder(borderRadius: BorderRadius.circular(10))`.
  * `enabledBorder`: Border abu-abu tipis `#E2E8F0`.
  * `focusedBorder`: Border biru primer 2px `#087F8C`.
  * `errorBorder`: Border merah hati 1.5px `#8B1E2B`.
* **Label & Icon:** Selalu menyertakan `labelText` dengan tanda bintang `*` untuk kolom wajib, disertai `prefixIcon` relevan.

### 5.4. Tombol Aksi (Buttons)
* **Tombol Primer (FilledButton):**
  * Background: `AppColors.primary` (`#087F8C`) atau `AppColors.navy` (`#123047`).
  * Teks putih tebal, radius sudut 10px, padding vertikal 12-14px.
* **Tombol Sekunder (OutlinedButton):**
  * Border 1px `#CBD5E1`, warna teks `#334155`.
* **Tombol Bahaya (Destructive Button):**
  * Background merah hati `#8B1E2B`, teks putih, untuk aksi batalkan/hapus.
* **Tombol Aksi Ikon (IconButton):**
  * Tooltip wajib disematkan untuk aksesibilitas (contoh: `tooltip: 'Panggil Suara Pasien'`).

### 5.5. Dialog Modal (Form Dialogs)
* **Radius Sudut:** 16px.
* **Header Modal:** Icon tema di kiri, judul tebal 16-18sp, deskripsi ringkas 12sp, tombol silang (close) di pojok kanan atas.
* **Body Modal:** Dibungkus dalam `SingleChildScrollView` untuk mencegah keyboard virtual menutupi input.
* **Footer Modal:** Tombol Batal di kiri, tombol Simpan / Konfirmasi di kanan.

---

## 6. Standar Suara dan Notifikasi Audio (Audio Queue Standards)

1. **Struktur Pengucapan Suara (Text-to-Speech):**
   * Panggilan antrean wajib diawali dengan nada bel RS (*hospital chime*).
   * Format kalimat: `"Panggilan nomor antrean, [EJAAN_ANTREAN]. Atas nama, [NAMA_PASIEN], silakan menuju ke [NAMA_POLI_ATAU_LOKET]. Terima kasih."`
   * Ejaan nomor antrean: Karakter dieja terpisah agar jelas di speaker publik (contoh: `A-001` dieja `"A, nol nol satu"`).
2. **Kontrol Suara di Dashboard:**
   * Setiap pemicu suara harus disertai konfirmasi visual berupa SnackBar di bagian bawah layar.

---

## 7. Standar Ekspor Laporan (Excel & CSV Standards)

1. **Header Dokumen Ekspor:**
   * Baris 1: Judul resmi laporan dalam huruf kapital.
   * Baris 2: Subjudul institusi (`SehatKu Hospital Management System`).
   * Baris 3: Rentang tanggal transaksi yang diekspor.
   * Baris 4: Waktu pembuatan ekspor (`DD/MM/YYYY HH:mm WIB`).
2. **Struktur Kolom:**
   * Kolom pertama wajib berupa nomor urut (`No`).
   * Format nominal mata uang berupa angka bulat bersih yang dapat langsung diformulasikan (`SUM`) di Microsoft Excel / Google Sheets.
3. **Ringkasan Finansial Eksekutif:**
   * Di bagian bawah tabel, wajib disediakan seksi ringkasan (Total Lunas, Total Tertunda, Total Akumulasi, Rata-rata Transaksi).
4. **Encoding File:**
   * Wajib menyertakan UTF-8 Byte Order Mark (`\uFEFF`) agar seluruh teks nama dokter, penjamin, dan aksen terbaca sempurna di seluruh sistem operasi.

---

## 8. Checklist Verifikasi Kualitas UI (Quality Assurance Checklist)

Sebelum kode diintegrasikan ke cabang utama, lakukan pengujian terhadap daftar periksa berikut:

- [ ] Tidak ada RenderFlex overflow saat diuji pada resolusi ponsel (lebar 360px) dan desktop (lebar 1440px).
- [ ] Seluruh dropdown memiliki `isExpanded: true` dan item teks dengan `TextOverflow.ellipsis`.
- [ ] Warna status badge mengikuti token semantik baku pada Seksi 2.4.
- [ ] Format mata uang konsisten menggunakan `Rp X.XXX.XXX`.
- [ ] Format tanggal dan jam konsisten menggunakan format 24 jam WIB.
- [ ] Seluruh tombol aksi memiliki status loading saat memproses API asynchronous.
- [ ] Tidak ada teks statis hardcoded yang bertentangan dengan state data di database.
- [ ] Dokumentasi Markdown bersih dari elemen tidak baku dan bebas dari karakter emoji.

---

## 9. Audit Warna UI & Pedoman Perbaikan Konsistensi (UI Color Audit & Remediation Guide)

Berdasarkan audit menyeluruh terhadap kode sumber front-end, berikut adalah area warna yang perlu diperbaiki dan diseragamkan:

### 9.1. Masalah Warna yang Diidentifikasi (Identified Color Inconsistencies)

1. **Penggunaan Warna Merah Acak (Generic Red vs Merah Hati SehatKu)**
   * **Masalah:** Beberapa dialog masih menggunakan `Colors.red` atau `Colors.red.shade700` mentah untuk status pembatalan, selisih minus kasir, atau tombol hapus.
   * **Perbaikan:** Wajib menggunakan token Merah Hati resmi:
     * Background: `AppColors.errorLight` (`#FBF0F1`)
     * Border: `AppColors.errorBorder` (`#E5A8AF`)
     * Teks & Icon: `AppColors.errorText` (`#6B111A`)
     * Tombol Aksi: `AppColors.error` (`#8B1E2B`)

2. **Kontras Rendah Teks Status Kuning/Oranye (Low Contrast Warning Text)**
   * **Masalah:** Penggunaan `Colors.orange` atau `Colors.amber` langsung sebagai warna teks di atas latar belakang putih/terang tidak memenuhi standar aksesibilitas WCAG AA (rasio kontras di bawah 3:1).
   * **Perbaikan:** Teks status peringatan atau menunggu wajib menggunakan warna oranye gelap dengan kontras tinggi `AppColors.warningText` (`#E65100` atau `#92400E`), dengan latar belakang `AppColors.warningLight` (`#FFF8E1`) dan border `#FFE082`.

3. **Inkonsistensi Warna Teal vs Brand Primary**
   * **Masalah:** Tombol aksi kasir, banner rekam medis, dan tombol filter terkadang menggunakan `Colors.teal` atau `Colors.teal.shade700` secara tidak seragam.
   * **Perbaikan:** Wajib menggunakan `AppColors.primary` (`#087F8C`) untuk aksi utama dan `AppColors.primaryDark` (`#055E68`) untuk state penekanan.

4. **Variasi Warna Abu-Abu (Grey Scale Sprawl)**
   * **Masalah:** Terdapat campuran pemanggilan `Colors.grey`, `Colors.grey.shade600`, `Colors.grey.shade700`, dan `Colors.black87` untuk teks sekunder.
   * **Perbaikan:** Menggunakan skala netral slate terstruktur:
     * Teks Utama: `AppColors.textPrimary` (`#123047`)
     * Teks Sekunder / Label: `AppColors.textSecondary` (`#405667`)
     * Teks Muted / Helper: `AppColors.textMuted` (`#607585`)
     * Border Pemisah: `AppColors.cardBorder` (`#E4EBEF`)
     * Background Canvas: `AppColors.background` (`#F5F8FA`)

### 9.2. Tabel Pemetaan Refactoring Warna (Color Migration Mapping)

| Kode Lama (Hindari) | Token Resmi Baru (Wajib) | Nilai HEX | Alasan / Rationale |
| :--- | :--- | :--- | :--- |
| `Colors.red` / `Colors.red.shade700` | `AppColors.error` | `#8B1E2B` | Menjaga identitas Merah Hati premium SehatKu. |
| `Colors.red.shade50` | `AppColors.errorLight` | `#FBF0F1` | Latar belakang badge/dialog bahaya yang lembut. |
| `Colors.orange` (sebagai teks) | `AppColors.warningText` | `#E65100` | Menjamin kontras keterbacaan WCAG AA > 4.5:1. |
| `Colors.amber.shade50` | `AppColors.warningLight` | `#FFF8E1` | Latar belakang badge status menunggu. |
| `Colors.green` (sebagai teks) | `AppColors.successText` | `#1B5E20` | Kontras tinggi teks status lunas/selesai. |
| `Colors.green.shade50` | `AppColors.successLight` | `#E8F5E9` | Latar belakang badge status berhasil. |
| `Colors.blue.shade900` | `AppColors.infoText` | `#0D47A1` | Teks status informasi/rawat jalan. |
| `Colors.blue.shade50` | `AppColors.infoLight` | `#E1F5FE` | Latar belakang badge status informasi. |
| `Colors.grey.shade200` | `AppColors.cardBorder` | `#E4EBEF` | Border pemisah tabel dan kontainer kartu. |
| `Colors.black87` | `AppColors.textPrimary` | `#123047` | Judul dan teks data utama berkarakter navy. |

---

## 10. Standar Penyeragaman Format Nominal Mata Uang Rupiah (IDR Currency Standard)

Seluruh komponen antarmuka SehatKu HMS wajib menggunakan format standar Bank Indonesia yang seragam untuk nominal Rupiah.

### 10.1. Aturan Baku Penulisan Nominal

1. **Format Lengkap (Full Currency):**
   * **Aturan:** Menggunakan prefix `Rp`, diikuti spasi tunggal, pemisah ribuan berupa titik (`.`), dan tanpa angka sen untuk nominal bulat.
   * **Contoh Benar:** `Rp 350.000`, `Rp 1.500.000`, `Rp 25.000`
   * **Implementasi:** `CurrencyFormatter.format(amount)`

2. **Format Ringkas Dashboard / Metrik (Compact Currency):**
   * **Aturan:** Digunakan khusus pada kartu ringkasan eksekutif (Stat Cards) di mana ruang layar terbatas. Menggunakan akhiran `Rb` (Ribu), `Jt` (Juta), atau `M` (Miliar) dengan 1 desimal opsional (tanda koma `,`).
   * **Contoh Benar:** `Rp 12,5 Jt`, `Rp 1,2 M`, `Rp 850 Rb`
   * **Implementasi:** `CurrencyFormatter.formatCompact(amount)`

3. **Format Input Form & TextField Kasir:**
   * **Aturan:** Input field menyertakan `prefixText: 'Rp '`, keyboard berjenis `TextInputType.number`, dan validasi regex pembersih karakter non-digit `[^0-9.]`.
   * **Helper:** `CurrencyFormatter.parse(controller.text)`

### 10.2. Larangan Format (Currency Anti-Patterns)

* **DILARANG:** Menuliskan `Rp.` dengan titik setelah singkatan Rp (contoh salah: `Rp. 150.000`).
* **DILARANG:** Menuliskan simbol internasional `IDR` pada UI visual pasien atau petugas kasir (contoh salah: `IDR 150.000` atau `150.000 IDR`). Simbol ISO `IDR` hanya diperbolehkan pada payload JSON backend.
* **DILARANG:** Menggunakan koma sebagai pemisah ribuan gaya Amerika/Inggris (contoh salah: `Rp 350,000`).
* **DILARANG:** Melakukan pemformatan manual regex ad-hoc string di dalam file widget. Seluruh modul wajib memanggil `CurrencyFormatter`.

---

## 11. Pedoman Anti-AI Slop & Estetika Klinis (Anti-AI Slop Guidelines)

Untuk menjaga citra profesional sistem rumah sakit dan menghindari visual yang tampak tidak matang atau hasil generate AI yang inkonsisten, patuhi aturan estetika berikut:

### 11.1. Definisi dan Pola AI Slop yang Dilarang

1. **Rainbow Pastel Cards (Kartu Warna-Warni Acak):**
   * *Pelanggaran:* Membuat 4 kartu statistik bersebelahan dengan latar warna ungu pastel, pink pastel, kuning pastel, dan hijau toska tanpa alasan semantik yang jelas.
   * *Solusi Standar:* Seluruh kartu menggunakan latar belakang putih bersih (`#FFFFFF`), border 1px lembut (`#E4EBEF`), dan aksen warna terbatas pada icon badge kecil sesuai makna semantik.

2. **Gradien Neon & Efek Blur Berlebihan:**
   * *Pelanggaran:* Memberikan efek glowing neon, shadow berwarna-warni cerah, atau gradien diagonal mencolok pada tombol biasa.
   * *Solusi Standar:* Menggunakan flat-clean design Material 3 dengan elevation 0 atau 1, serta shadow netral monokrom berkontur halus (`Colors.black.withValues(alpha: 0.04)`).

3. **Penggunaan Karakter Emoji:**
   * *Pelanggaran:* Menyisipkan emoji di dalam judul tab, pesan dialog, label status, atau dokumen cetak.
   * *Solusi Standar:* Wajib menggunakan icon Material resmi (`Icons.local_hospital`, `Icons.receipt_long`, `Icons.check_circle_outline`, dll.) yang terukur dan profesional.

4. **Inkonsistensi Radius Sudut (Corner Radius Sprawl):**
   * *Pelanggaran:* Menumpuk elemen dengan radius sudut acak (sebagian 4px, 8px, 18px, 30px, 99px).
   * *Solusi Standar:*
     * Kontainer Kartu Utama: `16px` / `20px`
     * Input Form & Dialog: `14px` / `16px`
     * Tombol Aksi (Button): `10px` / `12px`
     * Status Badges & Chips: `6px` / `8px`
     * Avatar & Indikator Lingkaran: Bulat Penuh (`50%` / Circle)

5. **Warna Semantik yang Bertentangan (Conflicting Status Mapping):**
   * *Pelanggaran:* Menggunakan warna ungu atau oranye untuk status 'LUNAS', atau warna biru untuk status 'DIBATALKAN'.
   * *Solusi Standar:* Taati tabel token status pada Seksi 2.4 secara ketat tanpa improvisasi warna lokal.

