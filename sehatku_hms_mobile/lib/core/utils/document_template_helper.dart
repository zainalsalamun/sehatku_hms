import 'package:intl/intl.dart';
import '../../shared/models/health_models.dart';

class DocumentTemplateHelper {
  static const String clinicName = 'KLINIK PRATAMA SEHATKU MEDIKA';
  static const String clinicLicense = 'Izin Operasional No: 445/092/DINKES/2023';
  static const String clinicAddress =
      'Jl. Jenderal Sudirman Kav. 52-53, Jakarta Selatan • Telp: (021) 555-8900';

  static String _numberToWords(int n) {
    const words = [
      'Nol',
      'Satu',
      'Dua',
      'Tiga',
      'Empat',
      'Lima',
      'Enam',
      'Tujuh',
      'Delapan',
      'Sembilan',
      'Sepuluh',
      'Sebelas',
      'Dua Belas',
      'Tiga Belas',
      'Empat Belas',
    ];
    if (n >= 0 && n < words.length) return words[n];
    return n.toString();
  }

  /// Generator untuk Surat Keterangan Medis (Sakit / Sehat)
  static String generateMedicalCertificateHtml(MedicalCertificate cert) {
    final isSickLeave = cert.type == 'sick_leave';
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');
    final formattedStart = dateFormat.format(cert.startDate);
    final formattedEnd = dateFormat.format(cert.endDate);
    final formattedToday = dateFormat.format(DateTime.now());

    final docTitle = isSickLeave
        ? 'SURAT KETERANGAN SAKIT'
        : 'SURAT KETERANGAN KESEHATAN';

    final bodyStatement = isSickLeave
        ? '''
        Berhubung sedang dalam keadaan sakit, pasien memerlukan istirahat tirah baring selama 
        <strong>${cert.durationDays} (${_numberToWords(cert.durationDays)}) hari</strong>, 
        terhitung mulai tanggal <strong>$formattedStart</strong> sampai dengan <strong>$formattedEnd</strong>.
        '''
        : '''
        Telah diperiksa kesehatan jasmaninya dan dinyatakan <strong>SEHAT</strong> pada hari ini untuk keperluan administratif / kegiatan kedinasan.
        ''';

    final notesHtml = cert.notes.isNotEmpty
        ? '''
        <div style="margin: 12px 0; font-size: 12px; color: #4a5568; font-style: italic;">
          Catatan Medis: ${cert.notes}
        </div>
        '''
        : '';

    return '''
      <table class="header-table">
        <tr>
          <td class="header-logo" style="width: 54px; height: 54px; background: #00796b; color: white; text-align: center; border-radius: 10px; font-size: 26px;">
            +
          </td>
          <td class="header-text">
            <div class="hospital-title">$clinicName</div>
            <div class="hospital-sub">$clinicLicense</div>
            <div class="hospital-address">$clinicAddress</div>
          </td>
        </tr>
      </table>

      <div class="divider-thick"></div>
      <div class="divider-thin"></div>

      <div class="doc-title">
        <h2>$docTitle</h2>
        <p>Nomor: ${cert.certificateNumber}</p>
      </div>

      <div class="content-body">
        Yang bertanda tangan di bawah ini, Dokter Pemeriksa Klinik Pratama SehatKu Medika menerangkan dengan sebenarnya bahwa:
      </div>

      <div class="info-box">
        <table class="info-table">
          <tr>
            <td class="info-label">Nama Pasien</td>
            <td class="info-sep">:</td>
            <td class="info-val"><strong>${cert.patientName}</strong></td>
          </tr>
          <tr>
            <td class="info-label">No. Rekam Medis (MRN)</td>
            <td class="info-sep">:</td>
            <td class="info-val">${cert.patientMrn}</td>
          </tr>
          <tr>
            <td class="info-label">Diagnosa Medis</td>
            <td class="info-sep">:</td>
            <td class="info-val">${cert.diagnosis.isNotEmpty ? cert.diagnosis : 'Pemeriksaan Rutin & Observasi Klinis'}</td>
          </tr>
        </table>
      </div>

      <div class="content-body">
        $bodyStatement
      </div>

      $notesHtml

      <div class="content-body" style="margin-top: 18px;">
        Demikian surat keterangan ini diberikan untuk dapat dipergunakan sebagaimana mestinya.
      </div>

      <table class="footer-table" style="margin-top: 36px;">
        <tr>
          <td class="qr-cell">
            <div style="display: flex; align-items: center;">
              <div style="display: inline-block; border: 1px solid #cbd5e1; padding: 6px; border-radius: 6px; background: #ffffff;">
                <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="#0d2b45" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                  <rect x="3" y="3" width="7" height="7"></rect>
                  <rect x="14" y="3" width="7" height="7"></rect>
                  <rect x="14" y="14" width="7" height="7"></rect>
                  <rect x="3" y="14" width="7" height="7"></rect>
                </svg>
              </div>
              <div class="verified-badge">
                TERVERIFIKASI<br>KLINIK SEHATKU
              </div>
            </div>
            <div style="font-size: 9px; color: #718096; margin-top: 6px;">
              Scan QR untuk validasi keaslian dokumen resmi
            </div>
          </td>
          <td class="sign-cell">
            <div style="font-size: 12px; color: #1a202c;">Jakarta, $formattedToday</div>
            <div style="font-size: 12px; color: #4a5568; margin-top: 2px;">Dokter Pemeriksa,</div>
            <div style="height: 48px;"></div>
            <div style="font-size: 13px; font-weight: bold; text-decoration: underline; color: #0d2b45;">
              ${cert.doctorName}
            </div>
            <div style="font-size: 10px; color: #718096; margin-top: 2px;">
              SIP. 449.1/023/DINKES/2021
            </div>
          </td>
        </tr>
      </table>
    ''';
  }

  /// Generator untuk Kwitansi / Bukti Pembayaran Resmi RS
  static String generateOfficialReceiptHtml({
    required Invoice invoice,
    List<Map<String, dynamic>> items = const [],
    String cashierName = 'Petugas Kasir POS',
  }) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
    final formattedDate = dateFormat.format(invoice.paidAt ?? invoice.createdAt);

    final displayItems = items.isNotEmpty
        ? items
        : [
            {
              'name': invoice.serviceName,
              'category': 'Pemeriksaan Klinis',
              'quantity': 1,
              'unitPrice': invoice.amount,
              'subtotal': invoice.amount,
            },
          ];

    final itemsRows = displayItems.map((it) {
      final name = it['name']?.toString() ?? 'Layanan Medis';
      final qty = (it['quantity'] as num?)?.toInt() ?? 1;
      final unitPrice = (it['unitPrice'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (it['subtotal'] as num?)?.toDouble() ?? 0.0;
      return '''
        <tr>
          <td>$name</td>
          <td style="text-align: center;">$qty</td>
          <td style="text-align: right;">${currency.format(unitPrice)}</td>
          <td style="text-align: right; font-weight: bold;">${currency.format(subtotal)}</td>
        </tr>
      ''';
    }).join('\n');

    return '''
      <table class="header-table">
        <tr>
          <td class="header-logo" style="width: 54px; height: 54px; background: #00796b; color: white; text-align: center; border-radius: 10px; font-size: 26px;">
            +
          </td>
          <td class="header-text">
            <div class="hospital-title">$clinicName</div>
            <div class="hospital-sub">$clinicLicense</div>
            <div class="hospital-address">$clinicAddress</div>
          </td>
        </tr>
      </table>

      <div class="divider-thick"></div>
      <div class="divider-thin"></div>

      <div class="doc-title">
        <h2>KWITANSI PEMBAYARAN RESMI</h2>
        <p>No. Transaksi: ${invoice.invoiceNumber}</p>
      </div>

      <div class="info-box">
        <table class="info-table">
          <tr>
            <td class="info-label">Nama Pasien</td>
            <td class="info-sep">:</td>
            <td class="info-val"><strong>${invoice.patientName}</strong> (${invoice.patientMrn})</td>
          </tr>
          <tr>
            <td class="info-label">Dokter Pemeriksa</td>
            <td class="info-sep">:</td>
            <td class="info-val">${invoice.doctorName}</td>
          </tr>
          <tr>
            <td class="info-label">Waktu Pembayaran</td>
            <td class="info-sep">:</td>
            <td class="info-val">$formattedDate WIB</td>
          </tr>
          <tr>
            <td class="info-label">Metode Pembayaran</td>
            <td class="info-sep">:</td>
            <td class="info-val">${invoice.paymentMethod.isNotEmpty ? invoice.paymentMethod : 'Tunai / QRIS'}</td>
          </tr>
          <tr>
            <td class="info-label">Status Tagihan</td>
            <td class="info-sep">:</td>
            <td class="info-val" style="color: #00796b;"><strong>LUNAS</strong></td>
          </tr>
        </table>
      </div>

      <table class="items-table">
        <thead>
          <tr>
            <th>Rincian Layanan / Obat</th>
            <th style="text-align: center; width: 60px;">Qty</th>
            <th style="text-align: right; width: 130px;">Harga Satuan</th>
            <th style="text-align: right; width: 140px;">Subtotal</th>
          </tr>
        </thead>
        <tbody>
          $itemsRows
        </tbody>
        <tfoot>
          <tr style="background: #f8fafc;">
            <td colspan="3" style="text-align: right; font-weight: bold; font-size: 13px;">GRAND TOTAL:</td>
            <td style="text-align: right; font-weight: 900; font-size: 14px; color: #0d2b45;">
              ${currency.format(invoice.amount)}
            </td>
          </tr>
        </tfoot>
      </table>

      <table class="footer-table" style="margin-top: 30px;">
        <tr>
          <td class="qr-cell">
            <div class="verified-badge" style="margin-left: 0;">
              LUNAS • TERVALIDASI SISTEM POS
            </div>
            <div style="font-size: 9px; color: #718096; margin-top: 6px;">
              Dokumen ini merupakan bukti pembayaran yang sah dari $clinicName
            </div>
          </td>
          <td class="sign-cell">
            <div style="font-size: 12px; color: #1a202c;">Kasir / Bendahara RS,</div>
            <div style="height: 48px;"></div>
            <div style="font-size: 13px; font-weight: bold; text-decoration: underline; color: #0d2b45;">
              $cashierName
            </div>
            <div style="font-size: 10px; color: #718096; margin-top: 2px;">
              Unit Kasir & Pelayanan Pasien
            </div>
          </td>
        </tr>
      </table>
    ''';
  }

  /// Generator untuk Etiket Stiker Obat Farmasi (Thermal Sticker / Label)
  static String generateMedicineLabelHtml({
    required PharmacyPrescription prescription,
    required List<PharmacyPrescriptionItem> items,
    String labelType = 'putih',
    String mealTiming = 'Sesudah Makan',
    bool morning = true,
    bool afternoon = true,
    bool night = true,
    bool mustFinish = false,
    bool shakeWell = false,
    String expiryDate = '',
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
    final formattedDate = dateFormat.format(prescription.createdAt);
    final expStr = expiryDate.isNotEmpty
        ? expiryDate
        : dateFormat.format(DateTime.now().add(const Duration(days: 180)));

    final renderedStickers = items.map((item) {
      final isBiru = labelType == 'biru' ||
          item.route.toLowerCase().contains('topikal') ||
          item.route.toLowerCase().contains('oles') ||
          item.medicineName.toLowerCase().contains('salep') ||
          item.medicineName.toLowerCase().contains('tetes') ||
          item.medicineName.toLowerCase().contains('gel') ||
          item.medicineName.toLowerCase().contains('cream');

      final isAntibiotik = mustFinish ||
          item.medicineName.toLowerCase().contains('amoxicillin') ||
          item.medicineName.toLowerCase().contains('ciprofloxacin') ||
          item.medicineName.toLowerCase().contains('azithromycin') ||
          item.medicineName.toLowerCase().contains('cef') ||
          item.medicineName.toLowerCase().contains('antibiotik');

      final isKocok = shakeWell ||
          item.dosage.toLowerCase().contains('sirup') ||
          item.dosage.toLowerCase().contains('suspensi') ||
          item.dosage.toLowerCase().contains('tetes');

      final headerBg = isBiru ? '#1d4ed8' : '#ffffff';
      final headerTextColor = isBiru ? '#ffffff' : '#0f172a';
      final headerSubColor = isBiru ? '#e0e7ff' : '#64748b';
      final borderColor = isBiru ? '#1d4ed8' : '#334155';

      final outerBadge = isBiru
          ? '''
          <div style="background: #fef08a; color: #854d0e; font-weight: 900; font-size: 10px; padding: 3px 6px; text-align: center; border-radius: 4px; margin-top: 4px; letter-spacing: 0.5px;">
            OBAT LUAR - TIDAK BOLEH DITELAN
          </div>
          '''
          : '';

      final finishBadge = isAntibiotik
          ? '''
          <div style="background: #fee2e2; color: #991b1b; font-weight: 800; font-size: 9px; padding: 2px 4px; text-align: center; border-radius: 4px; margin-top: 4px; border: 1px solid #fca5a5;">
            HARUS DIHABISKAN (ANTIBIOTIK)
          </div>
          '''
          : '';

      final shakeBadge = isKocok
          ? '''
          <div style="background: #ffedd5; color: #9a3412; font-weight: 800; font-size: 9px; padding: 2px 4px; text-align: center; border-radius: 4px; margin-top: 4px; border: 1px solid #fdba74;">
            KOCOK DAHULU SEBELUM DIMINUM / DIGUNAKAN
          </div>
          '''
          : '';

      final pagiActive = morning
          ? 'background: #1e293b; color: #ffffff;'
          : 'background: #f1f5f9; color: #94a3b8;';
      final siangActive = afternoon
          ? 'background: #1e293b; color: #ffffff;'
          : 'background: #f1f5f9; color: #94a3b8;';
      final malamActive = night
          ? 'background: #1e293b; color: #ffffff;'
          : 'background: #f1f5f9; color: #94a3b8;';

      return '''
      <div style="width: 340px; border: 2px solid $borderColor; border-radius: 8px; overflow: hidden; background: #ffffff; margin: 0 auto 24px auto; page-break-inside: avoid; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;">
        <!-- Header -->
        <div style="background: $headerBg; color: $headerTextColor; padding: 8px 10px; text-align: center; border-bottom: 1px solid #e2e8f0;">
          <div style="font-size: 11px; font-weight: 900; letter-spacing: 0.5px;">$clinicName</div>
          <div style="font-size: 8px; color: $headerSubColor; margin-top: 2px; line-height: 1.2;">
            SIA: 445/SIA/089/2023 • SIPA: 1988/SIPA/2024<br>
            $clinicAddress
          </div>
          $outerBadge
        </div>

        <!-- Body -->
        <div style="padding: 10px;">
          <div style="display: flex; justify-content: space-between; font-size: 9px; margin-bottom: 4px;">
            <div><strong>No. Resep:</strong> ${prescription.prescriptionNumber}</div>
            <div style="color: #64748b;">$formattedDate</div>
          </div>
          <div style="font-size: 11px; margin-bottom: 8px;">
            <strong>Pasien:</strong> ${prescription.patientName} (${prescription.patientMrn})
          </div>

          <div style="border-top: 1px dashed #cbd5e1; padding-top: 8px; text-align: center;">
            <div style="font-size: 14px; font-weight: 900; color: #0f172a; letter-spacing: 0.3px;">
              ${item.medicineName.toUpperCase()}
            </div>
            <div style="font-size: 10px; color: #475569; margin-top: 2px;">
              Sediaan / Dosis: ${item.dosage}
            </div>
          </div>

          <!-- Usage badge -->
          <div style="margin: 8px 0; background: ${isBiru ? '#eff6ff' : '#f0fdf4'}; border: 1px solid ${isBiru ? '#bfdbfe' : '#bbf7d0'}; border-radius: 6px; padding: 6px; text-align: center;">
            <div style="font-size: 13px; font-weight: 900; color: ${isBiru ? '#1e40af' : '#166534'};">
              ${item.frequency.toUpperCase()}
            </div>
            <div style="font-size: 10px; font-weight: bold; color: ${isBiru ? '#1d4ed8' : '#15803d'}; margin-top: 2px;">
              ${mealTiming.toUpperCase()}
            </div>
          </div>

          <!-- Time Checkers -->
          <table style="width: 100%; border-collapse: collapse; margin-bottom: 6px;">
            <tr>
              <td style="text-align: center; padding: 2px;"><span style="display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 9px; font-weight: 800; $pagiActive">PAGI</span></td>
              <td style="text-align: center; padding: 2px;"><span style="display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 9px; font-weight: 800; $siangActive">SIANG</span></td>
              <td style="text-align: center; padding: 2px;"><span style="display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 9px; font-weight: 800; $malamActive">MALAM</span></td>
            </tr>
          </table>

          $finishBadge
          $shakeBadge

          <div style="border-top: 1px solid #e2e8f0; margin-top: 8px; padding-top: 6px; display: flex; justify-content: space-between; font-size: 8.5px; color: #64748b;">
            <div>Exp/BUD: <strong>$expStr</strong></div>
            <div>Dokter: <strong>${prescription.doctorName}</strong></div>
          </div>
        </div>
      </div>
      ''';
    }).join('\n');

    return '''
      <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 10px;">
        $renderedStickers
      </div>
    ''';
  }

  /// Generator untuk Stiker Label Berkas Rekam Medis (MRN) Pasien
  static String generatePatientMrnLabelHtml({
    required PharmacyPrescription prescription,
    Patient? patient,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final birthDateStr = patient != null
        ? dateFormat.format(patient.birthDate)
        : '01 Jan 1995';
    final gender = patient?.gender ?? 'Laki-laki';
    final nik = patient?.nik ?? ('${prescription.patientMrn.replaceAll(RegExp(r'[^0-9]'), '')}00000000').substring(0, 16);
    final insurance = patient?.insuranceProvider ?? prescription.insurance;

    return '''
      <div style="width: 380px; margin: 20px auto; border: 2px solid #0f172a; border-radius: 10px; padding: 16px; background: #ffffff; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; box-sizing: border-box; page-break-inside: avoid;">
        <!-- Header -->
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 8px;">
          <tr>
            <td style="width: 24px; vertical-align: middle; color: #00796b; font-size: 20px; font-weight: 900;">
              +
            </td>
            <td style="vertical-align: middle;">
              <div style="font-size: 11px; font-weight: 900; letter-spacing: 0.5px; color: #0f172a;">$clinicName</div>
            </td>
            <td style="text-align: right; vertical-align: middle;">
              <span style="background: #e6fffa; color: #00796b; font-size: 9px; font-weight: 900; padding: 2px 6px; border-radius: 4px; border: 1px solid #b2f5ea;">
                LABEL RM
              </span>
            </td>
          </tr>
        </table>

        <div style="height: 1.5px; background: #0f172a; margin: 4px 0 10px 0;"></div>

        <!-- Big MRN & Barcode/QR Row -->
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 8px;">
          <tr>
            <td style="vertical-align: middle;">
              <div style="font-size: 9px; font-weight: bold; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px;">
                No. Rekam Medis (MRN):
              </div>
              <div style="font-size: 22px; font-weight: 900; color: #0f172a; letter-spacing: 1.5px; margin-top: 2px;">
                ${prescription.patientMrn}
              </div>
            </td>
            <td style="width: 60px; text-align: right; vertical-align: middle;">
              <div style="display: inline-block; border: 1px solid #cbd5e1; padding: 4px; border-radius: 6px; background: #f8fafc;">
                <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="#0f172a" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                  <rect x="3" y="3" width="7" height="7"></rect>
                  <rect x="14" y="3" width="7" height="7"></rect>
                  <rect x="14" y="14" width="7" height="7"></rect>
                  <rect x="3" y="14" width="7" height="7"></rect>
                </svg>
              </div>
            </td>
          </tr>
        </table>

        <!-- Patient Details Table -->
        <table style="width: 100%; border-collapse: collapse; font-size: 11px; margin-top: 6px;">
          <tr>
            <td style="width: 110px; padding: 3px 0; color: #475569;">Nama Pasien</td>
            <td style="width: 10px; padding: 3px 0;">:</td>
            <td style="padding: 3px 0; font-weight: bold; color: #0f172a;">${prescription.patientName}</td>
          </tr>
          <tr>
            <td style="padding: 3px 0; color: #475569;">NIK</td>
            <td style="padding: 3px 0;">:</td>
            <td style="padding: 3px 0; color: #0f172a;">$nik</td>
          </tr>
          <tr>
            <td style="padding: 3px 0; color: #475569;">Tanggal Lahir / JK</td>
            <td style="padding: 3px 0;">:</td>
            <td style="padding: 3px 0; color: #0f172a;">$birthDateStr • $gender</td>
          </tr>
          <tr>
            <td style="padding: 3px 0; color: #475569;">Penjamin</td>
            <td style="padding: 3px 0;">:</td>
            <td style="padding: 3px 0; color: #0f172a;">$insurance</td>
          </tr>
        </table>

        <div style="border-top: 1px dashed #cbd5e1; margin-top: 10px; padding-top: 6px; font-size: 8px; color: #64748b; font-style: italic;">
          Gunakan stiker ini untuk ditempel pada Map Rekam Medis, Gelang Pasien, atau Tabung Laboratorium.
        </div>
      </div>
    ''';
  }

  /// Generator untuk Karcis Nomor Antrean (Thermal 58mm / 80mm POS Ticket)
  static String generateQueueTicketHtml({
    required String queueNumber,
    required String patientName,
    String patientMrn = '',
    required String doctorName,
    required String department,
    String dateLabel = '',
    String time = '',
    String insurance = 'Umum / Mandiri',
    String status = 'Menunggu',
  }) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    final formattedNow = dateFormat.format(DateTime.now());
    final displayDate = dateLabel.isNotEmpty ? dateLabel : 'Hari Ini';
    final displayTime = time.isNotEmpty ? '$time WIB' : '';

    return '''
      <div style="width: 320px; margin: 10px auto; padding: 16px 14px; border: 1.5px dashed #334155; border-radius: 8px; background: #ffffff; font-family: 'Courier New', Courier, monospace, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto; color: #0f172a; box-sizing: border-box; page-break-inside: avoid;">
        <!-- Header Klinik -->
        <div style="text-align: center; border-bottom: 1.5px solid #0f172a; padding-bottom: 8px; margin-bottom: 10px;">
          <div style="font-size: 13px; font-weight: 900; letter-spacing: 0.5px; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;">
            $clinicName
          </div>
          <div style="font-size: 8.5px; color: #475569; margin-top: 2px; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;">
            $clinicAddress
          </div>
          <div style="font-size: 8px; color: #64748b; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;">
            $clinicLicense
          </div>
        </div>

        <div style="text-align: center; margin-bottom: 6px;">
          <div style="font-size: 11px; font-weight: 900; letter-spacing: 1px;">KARCIS NOMOR ANTREAN</div>
          <div style="font-size: 8.5px; color: #64748b; margin-top: 2px;">$formattedNow WIB</div>
        </div>

        <!-- Big Queue Number Box -->
        <div style="text-align: center; background: #f8fafc; border: 2px solid #0f172a; border-radius: 8px; padding: 12px 6px; margin: 8px 0;">
          <div style="font-size: 9px; font-weight: bold; color: #475569; text-transform: uppercase; letter-spacing: 1px;">
            NOMOR ANTREAN ANDA
          </div>
          <div style="font-size: 42px; font-weight: 900; letter-spacing: 2px; color: #0f172a; margin: 4px 0; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;">
            $queueNumber
          </div>
          <div style="font-size: 10px; font-weight: bold; color: #00796b;">
            $department
          </div>
        </div>

        <!-- Ticket Info Table -->
        <table style="width: 100%; border-collapse: collapse; font-size: 10px; margin: 10px 0;">
          <tr>
            <td style="width: 90px; padding: 2.5px 0; color: #475569;">Nama Pasien</td>
            <td style="width: 10px; padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0; font-weight: bold;">$patientName</td>
          </tr>
          ${patientMrn.isNotEmpty ? '''
          <tr>
            <td style="padding: 2.5px 0; color: #475569;">No. RM (MRN)</td>
            <td style="padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0;">$patientMrn</td>
          </tr>
          ''' : ''}
          <tr>
            <td style="padding: 2.5px 0; color: #475569;">Dokter</td>
            <td style="padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0; font-weight: bold;">$doctorName</td>
          </tr>
          <tr>
            <td style="padding: 2.5px 0; color: #475569;">Poli / Klinik</td>
            <td style="padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0;">$department</td>
          </tr>
          <tr>
            <td style="padding: 2.5px 0; color: #475569;">Penjamin</td>
            <td style="padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0;">$insurance</td>
          </tr>
          <tr>
            <td style="padding: 2.5px 0; color: #475569;">Jadwal / Sesi</td>
            <td style="padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0;">$displayDate ${displayTime.isNotEmpty ? '• $displayTime' : ''}</td>
          </tr>
          <tr>
            <td style="padding: 2.5px 0; color: #475569;">Status</td>
            <td style="padding: 2.5px 0;">:</td>
            <td style="padding: 2.5px 0; color: #00796b; font-weight: bold;">${status.toUpperCase()}</td>
          </tr>
        </table>

        <!-- QR Code Box -->
        <div style="text-align: center; margin: 10px 0 6px 0;">
          <div style="display: inline-block; border: 1px solid #cbd5e1; padding: 4px; border-radius: 6px; background: #ffffff;">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#0f172a" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="3" width="7" height="7"></rect>
              <rect x="14" y="3" width="7" height="7"></rect>
              <rect x="14" y="14" width="7" height="7"></rect>
              <rect x="3" y="14" width="7" height="7"></rect>
            </svg>
          </div>
          <div style="font-size: 8px; color: #64748b; margin-top: 2px;">
            Scan QR di Kiosk untuk Check-in otomatis
          </div>
        </div>

        <div style="border-top: 1px dashed #94a3b8; margin-top: 8px; padding-top: 8px; text-align: center; font-size: 8px; color: #64748b; line-height: 1.3;">
          <div>Perhatikan panggilan nomor antrean Anda di layar monitor.</div>
          <div style="margin-top: 2px;">Simpan karcis ini hingga seluruh rangkaian pelayanan selesai.</div>
          <div style="margin-top: 4px; font-weight: bold; color: #0f172a;">Semoga Lekas Sembuh</div>
        </div>
      </div>
    ''';
  }

  /// Generator untuk Lembar Resume Medis Rawat Inap & Surat Kontrol Pasien (Discharge Summary)
  static String generateInpatientDischargeSummaryHtml({
    required InpatientAdmissionModel admission,
    List<Map<String, String>>? homeMedications,
    String? controlDate,
    String? controlClinic,
    String? emergencyInstructions,
  }) {
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');
    final formattedAdmission = dateFormat.format(admission.admissionDate);
    final dischargeDt = admission.dischargeDate ?? DateTime.now();
    final formattedDischarge = dateFormat.format(dischargeDt);
    final formattedToday = dateFormat.format(DateTime.now());

    final days = admission.totalDays > 0
        ? admission.totalDays
        : (dischargeDt.difference(admission.admissionDate).inDays <= 0
            ? 1
            : dischargeDt.difference(admission.admissionDate).inDays + 1);

    final defaultMeds = homeMedications ?? [
      {
        'name': 'Cefixime 100 mg Tablet',
        'dosage': '2 x 1 Tablet',
        'timing': 'Sesudah makan',
        'duration': '5 Hari (Harus Dihabiskan)',
      },
      {
        'name': 'Paracetamol 500 mg Tablet',
        'dosage': '3 x 1 Tablet',
        'timing': 'Sesudah makan (Bila demam / nyeri)',
        'duration': '3 Hari',
      },
      {
        'name': 'Omeprazole 20 mg Kapsul',
        'dosage': '1 x 1 Kapsul',
        'timing': '30 menit sebelum sarapan',
        'duration': '5 Hari',
      },
    ];

    final medsRows = defaultMeds.map((med) {
      return '''
        <tr>
          <td style="padding: 6px 10px; border-bottom: 1px solid #e2e8f0; font-weight: bold; font-size: 11px;">
            ${med['name']}
          </td>
          <td style="padding: 6px 10px; border-bottom: 1px solid #e2e8f0; font-size: 11px;">
            ${med['dosage']}
          </td>
          <td style="padding: 6px 10px; border-bottom: 1px solid #e2e8f0; font-size: 11px;">
            ${med['timing']}
          </td>
          <td style="padding: 6px 10px; border-bottom: 1px solid #e2e8f0; font-size: 11px; text-align: right;">
            ${med['duration']}
          </td>
        </tr>
      ''';
    }).join('\n');

    final defaultControl = controlDate ??
        dateFormat.format(DateTime.now().add(const Duration(days: 4)));
    final clinic = controlClinic ?? 'Poli ${admission.doctorSpecialist}';

    return '''
      <table class="header-table">
        <tr>
          <td class="header-logo" style="width: 54px; height: 54px; background: #00796b; color: white; text-align: center; border-radius: 10px; font-size: 26px;">
            +
          </td>
          <td class="header-text">
            <div class="hospital-title">$clinicName</div>
            <div class="hospital-sub">$clinicLicense • Terakreditasi Paripurna KARS</div>
            <div class="hospital-address">$clinicAddress</div>
          </td>
        </tr>
      </table>

      <div class="divider-thick"></div>
      <div class="divider-thin"></div>

      <div class="doc-title" style="margin-top: 12px; margin-bottom: 14px;">
        <h2 style="font-size: 15px; margin: 0; color: #0f172a;">RINGKASAN PULANG RAWAT INAP & SURAT KONTROL</h2>
        <div style="font-size: 11px; font-weight: bold; color: #00796b; letter-spacing: 0.5px; margin-top: 2px;">
          INPATIENT CLINICAL DISCHARGE SUMMARY (KARS / RME STANDAR)
        </div>
        <p style="font-size: 11px; color: #64748b; margin-top: 2px;">No. Admisi: ${admission.admissionNumber}</p>
      </div>

      <div class="info-box" style="margin-bottom: 12px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 14px;">
        <table class="info-table" style="width: 100%; border-collapse: collapse; font-size: 11px;">
          <tr>
            <td class="info-label" style="width: 140px; color: #64748b; padding: 3px 0;">Nama Pasien</td>
            <td class="info-sep" style="width: 10px; padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;"><strong>${admission.patientName}</strong> (${admission.patientGender})</td>
            <td class="info-label" style="width: 140px; color: #64748b; padding: 3px 0;">Dokter DPJP</td>
            <td class="info-sep" style="width: 10px; padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;"><strong>${admission.doctorName}</strong></td>
          </tr>
          <tr>
            <td class="info-label" style="color: #64748b; padding: 3px 0;">No. RM (MRN)</td>
            <td class="info-sep" style="padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;">${admission.patientMrn}</td>
            <td class="info-label" style="color: #64748b; padding: 3px 0;">Ruang / Kelas</td>
            <td class="info-sep" style="padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;">${admission.roomName} (${admission.bedNumber}) - ${admission.classType}</td>
          </tr>
          <tr>
            <td class="info-label" style="color: #64748b; padding: 3px 0;">Tgl Masuk (MRS)</td>
            <td class="info-sep" style="padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;">$formattedAdmission</td>
            <td class="info-label" style="color: #64748b; padding: 3px 0;">Tgl Keluar (KRS)</td>
            <td class="info-sep" style="padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;">$formattedDischarge ($days Hari)</td>
          </tr>
          <tr>
            <td class="info-label" style="color: #64748b; padding: 3px 0;">Penjamin Biaya</td>
            <td class="info-sep" style="padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0;">${admission.patientInsurance}</td>
            <td class="info-label" style="color: #64748b; padding: 3px 0;">Kondisi Keluar</td>
            <td class="info-sep" style="padding: 3px 0;">:</td>
            <td class="info-val" style="padding: 3px 0; color: #166534; font-weight: bold;">${admission.dischargeCondition ?? "Sembuh (Klinis Stabil)"}</td>
          </tr>
        </table>
      </div>

      <!-- Ringkasan Diagnosa -->
      <div style="border: 1px solid #cbd5e1; border-radius: 8px; padding: 10px 14px; margin-bottom: 12px;">
        <div style="font-size: 11px; font-weight: bold; color: #0f172a; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px; margin-bottom: 6px;">
          RINGKASAN DIAGNOSA & OBSERVASI KLINIS
        </div>
        <table style="width: 100%; border-collapse: collapse; font-size: 11px;">
          <tr>
            <td style="width: 140px; color: #475569; padding: 3px 0;">Diagnosa Masuk (Admission Dx)</td>
            <td style="width: 10px;">:</td>
            <td style="font-weight: 500;">${admission.initialDiagnosis ?? "-"}</td>
          </tr>
          <tr>
            <td style="color: #475569; padding: 3px 0;">Diagnosa Akhir (Discharge Dx)</td>
            <td>:</td>
            <td style="font-weight: bold; color: #00796b;">${admission.dischargeDiagnosis ?? (admission.initialDiagnosis != null ? "${admission.initialDiagnosis} - Klinis Stabil" : "Kondisi Klinis Membaik")}</td>
          </tr>
          <tr>
            <td style="color: #475569; padding: 3px 0;">Instruksi Klinis Terakhir</td>
            <td>:</td>
            <td style="font-style: italic; color: #334155;">${admission.latestCPPT?.instruction?.isNotEmpty == true ? admission.latestCPPT!.instruction! : (admission.notes ?? "Pasien diijinkan pulang rawat jalan, lanjutkan terapi obat rumah.")}</td>
          </tr>
        </table>
      </div>

      <!-- Terapi Obat Pulang (Home Medications) -->
      <div style="margin-bottom: 12px;">
        <div style="font-size: 11px; font-weight: bold; color: #0f172a; margin-bottom: 6px;">
          TERAPI OBAT PULANG (HOME MEDICATIONS)
        </div>
        <table style="width: 100%; border-collapse: collapse; font-size: 10.5px; border: 1px solid #cbd5e1; border-radius: 6px; overflow: hidden;">
          <thead>
            <tr style="background: #f1f5f9; color: #334155;">
              <th style="padding: 6px 10px; text-align: left; border-bottom: 1px solid #cbd5e1;">Nama Obat & Sediaan</th>
              <th style="padding: 6px 10px; text-align: left; border-bottom: 1px solid #cbd5e1; width: 110px;">Dosis / Aturan</th>
              <th style="padding: 6px 10px; text-align: left; border-bottom: 1px solid #cbd5e1; width: 140px;">Waktu Konsumsi</th>
              <th style="padding: 6px 10px; text-align: right; border-bottom: 1px solid #cbd5e1; width: 130px;">Durasi / Keterangan</th>
            </tr>
          </thead>
          <tbody>
            $medsRows
          </tbody>
        </table>
      </div>

      <!-- Jadwal Kontrol & Edukasi Bahaya -->
      <div style="background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 10px 14px; margin-bottom: 14px;">
        <div style="font-size: 11px; font-weight: bold; color: #1e40af; margin-bottom: 4px;">
          JADWAL KONTROL POLIKLINIK RAWAT JALAN
        </div>
        <table style="width: 100%; border-collapse: collapse; font-size: 11px;">
          <tr>
            <td style="width: 140px; color: #1e3a8a; padding: 2px 0;">Hari / Tanggal Kontrol</td>
            <td style="width: 10px;">:</td>
            <td style="font-weight: bold; color: #1e3a8a;">$defaultControl</td>
          </tr>
          <tr>
            <td style="color: #1e3a8a; padding: 2px 0;">Poliklinik Tujuan</td>
            <td>:</td>
            <td style="font-weight: 500; color: #1e3a8a;">$clinic (DPJP: ${admission.doctorName})</td>
          </tr>
          <tr>
            <td style="color: #b91c1c; padding: 4px 0; font-weight: bold;" colspan="3">
              Perhatian: Segera hubungi IGD (021-555-8900) jika timbul demam tinggi > 38.5 C, sesak napas berat, nyeri dada, atau perdarahan aktif.
            </td>
          </tr>
        </table>
      </div>

      <!-- Legalitas & TTD DPJP -->
      <table class="footer-table" style="margin-top: 16px;">
        <tr>
          <td class="qr-cell" style="vertical-align: bottom;">
            <div style="display: flex; align-items: center;">
              <div style="display: inline-block; border: 1px solid #cbd5e1; padding: 6px; border-radius: 6px; background: #ffffff;">
                <svg width="52" height="52" viewBox="0 0 24 24" fill="none" stroke="#0d2b45" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                  <rect x="3" y="3" width="7" height="7"></rect>
                  <rect x="14" y="3" width="7" height="7"></rect>
                  <rect x="14" y="14" width="7" height="7"></rect>
                  <rect x="3" y="14" width="7" height="7"></rect>
                </svg>
              </div>
              <div class="verified-badge" style="margin-left: 8px;">
                DOKUMEN RESMI RME<br>TERVALIDASI KARS
              </div>
            </div>
            <div style="font-size: 9px; color: #64748b; margin-top: 4px;">
              Dokumen rekam medis elektronik ini sah sesuai UU Kesehatan No. 17/2023.
            </div>
          </td>
          <td class="sign-cell" style="text-align: right; vertical-align: bottom;">
            <div style="font-size: 11px; color: #1e293b;">Jakarta, $formattedToday</div>
            <div style="font-size: 11px; color: #64748b; margin-top: 2px;">Dokter Penanggung Jawab Pelayanan (DPJP),</div>
            <div style="height: 40px;"></div>
            <div style="font-size: 12px; font-weight: bold; text-decoration: underline; color: #0f172a;">
              ${admission.doctorName}
            </div>
            <div style="font-size: 10px; color: #64748b; margin-top: 2px;">
              ${admission.doctorSpecialist}
            </div>
          </td>
        </tr>
      </table>
    ''';
  }

  /// Generator untuk Dokumen Cetak / PDF Laporan Eksekutif Rumah Sakit
  static String generateExecutiveReportHtml({
    required String reportTitle,
    required String reportSubtitle,
    required String period,
    required String csvContent,
  }) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
    final formattedNow = dateFormat.format(DateTime.now());

    final cleanContent = csvContent.replaceAll('\uFEFF', '').trim();
    final rawLines = cleanContent.split(RegExp(r'\r?\n'));

    int tableHeaderIndex = -1;
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].toLowerCase();
      if (line.startsWith('no,') ||
          line.startsWith('no;') ||
          line.startsWith('"no"') ||
          line.contains('kode') ||
          line.contains('invoice') ||
          line.contains('no. admisi')) {
        tableHeaderIndex = i;
        break;
      }
    }

    final List<String> headerCols = [];
    final List<List<String>> dataRows = [];
    final List<String> summaryLines = [];

    if (tableHeaderIndex != -1) {
      final headerLine = rawLines[tableHeaderIndex];
      headerCols.addAll(_parseCsvLine(headerLine));

      for (int i = tableHeaderIndex + 1; i < rawLines.length; i++) {
        final line = rawLines[i].trim();
        if (line.isEmpty) continue;
        if (line.toLowerCase().contains('ringkasan') ||
            (line.toLowerCase().contains('total') &&
                !RegExp(r'^[0-9]').hasMatch(line))) {
          summaryLines.add(line);
          continue;
        }
        if (summaryLines.isNotEmpty) {
          summaryLines.add(line);
          continue;
        }

        final parsed = _parseCsvLine(line);
        if (parsed.isNotEmpty) {
          dataRows.add(parsed);
        }
      }
    }

    final thead = headerCols
        .map((c) =>
            '<th style="padding: 6px 8px; border: 1px solid #cbd5e1; background: #f1f5f9; font-size: 10px; text-align: left;">$c</th>')
        .join('');
    final tbody = dataRows.map((row) {
      final cells = row
          .map((cell) =>
              '<td style="padding: 5px 8px; border: 1px solid #e2e8f0; font-size: 10px;">$cell</td>')
          .join('');
      return '<tr>$cells</tr>';
    }).join('\n');

    final summaryHtml = summaryLines.isNotEmpty
        ? '''
        <div style="margin-top: 16px; padding: 12px 14px; background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px;">
          <div style="font-weight: bold; font-size: 11px; color: #0f172a; margin-bottom: 6px;">RINGKASAN & AGREGASI EKSEKUTIF:</div>
          <table style="width: 100%; border-collapse: collapse; font-size: 10.5px;">
            ${summaryLines.map((s) {
              final parts = s.split(RegExp(r'[,;]'));
              if (parts.length >= 2) {
                return '<tr><td style="padding: 2px 0; color: #475569; width: 320px;">${parts[0].replaceAll('"', '')}</td><td style="padding: 2px 0; font-weight: bold; color: #0f172a;">: ${parts[1].replaceAll('"', '')}</td></tr>';
              }
              return '<tr><td colspan="2" style="padding: 2px 0; font-weight: bold; color: #00796b;">${s.replaceAll('"', '')}</td></tr>';
            }).join('\n')}
          </table>
        </div>
        '''
        : '';

    return '''
      <table class="header-table">
        <tr>
          <td class="header-logo" style="width: 50px; height: 50px; background: #00796b; color: white; text-align: center; border-radius: 10px; font-size: 24px;">
            +
          </td>
          <td class="header-text">
            <div class="hospital-title">$clinicName</div>
            <div class="hospital-sub">$clinicLicense • Terakreditasi Paripurna KARS</div>
            <div class="hospital-address">$clinicAddress</div>
          </td>
        </tr>
      </table>

      <div class="divider-thick"></div>
      <div class="divider-thin"></div>

      <div class="doc-title" style="margin-top: 12px; margin-bottom: 12px;">
        <h2 style="font-size: 14px; margin: 0; color: #0f172a;">$reportTitle</h2>
        <p style="font-size: 11px; color: #64748b; margin-top: 2px;">$reportSubtitle</p>
      </div>

      <div class="info-box" style="margin-bottom: 12px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 8px 12px;">
        <table style="width: 100%; border-collapse: collapse; font-size: 10.5px;">
          <tr>
            <td style="width: 120px; color: #64748b;">Periode Data</td>
            <td style="width: 10px;">:</td>
            <td style="font-weight: bold; color: #0f172a;">$period</td>
            <td style="width: 120px; color: #64748b;">Waktu Cetak</td>
            <td style="width: 10px;">:</td>
            <td style="color: #0f172a;">$formattedNow WIB</td>
          </tr>
        </table>
      </div>

      <div style="overflow-x: auto; margin-bottom: 14px;">
        <table style="width: 100%; border-collapse: collapse; border: 1px solid #cbd5e1;">
          <thead><tr>$thead</tr></thead>
          <tbody>$tbody</tbody>
        </table>
      </div>

      $summaryHtml

      <table class="footer-table" style="margin-top: 24px;">
        <tr>
          <td class="qr-cell" style="vertical-align: bottom;">
            <div style="font-size: 9px; color: #64748b;">
              Laporan terverifikasi otomatis oleh Sistem Informasi Rumah Sakit SehatKu HMS.
            </div>
          </td>
          <td class="sign-cell" style="text-align: right; vertical-align: bottom;">
            <div style="font-size: 11px; color: #1e293b;">Jakarta, $formattedNow WIB</div>
            <div style="font-size: 11px; color: #64748b; margin-top: 2px;">Direksi / Penanggung Jawab RS,</div>
            <div style="height: 38px;"></div>
            <div style="font-size: 12px; font-weight: bold; text-decoration: underline; color: #0f172a;">
              dr. H. Prasetyo Wibowo, MARS
            </div>
            <div style="font-size: 10px; color: #64748b; margin-top: 2px;">
              Direktur Utama Rumah Sakit
            </div>
          </td>
        </tr>
      </table>
    ''';
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer cur = StringBuffer();
    bool insideQuote = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuote = !insideQuote;
      } else if ((char == ',' || char == ';') && !insideQuote) {
        result.add(cur.toString().trim());
        cur.clear();
      } else {
        cur.write(char);
      }
    }
    result.add(cur.toString().trim());
    return result;
  }
}


