// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void printHtmlDocument({
  required String title,
  required String htmlContent,
}) {
  final fullHtml = '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <style>
    @page {
      size: A4;
      margin: 15mm 20mm;
    }
    @media print {
      body {
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }
      .no-print {
        display: none !important;
      }
    }
    * {
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      color: #1a202c;
      background: #ffffff;
      margin: 0;
      padding: 24px;
      line-height: 1.5;
    }
    .print-container {
      max-width: 780px;
      margin: 0 auto;
      background: #ffffff;
    }
    .header-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 8px;
    }
    .header-logo {
      width: 56px;
      height: 56px;
      background: #00796b;
      border-radius: 12px;
      text-align: center;
      vertical-align: middle;
      color: #ffffff;
      font-size: 28px;
      font-weight: 900;
    }
    .header-text {
      padding-left: 16px;
      vertical-align: middle;
    }
    .hospital-title {
      font-size: 17px;
      font-weight: 900;
      color: #0d2b45;
      margin: 0 0 2px 0;
      letter-spacing: 0.5px;
    }
    .hospital-sub {
      font-size: 11px;
      color: #4a5568;
      margin: 0 0 2px 0;
    }
    .hospital-address {
      font-size: 10px;
      color: #718096;
      margin: 0;
    }
    .divider-thick {
      height: 2px;
      background-color: #0d2b45;
      margin: 8px 0 2px 0;
    }
    .divider-thin {
      height: 0.8px;
      background-color: #0d2b45;
      margin: 0 0 18px 0;
    }
    .doc-title {
      text-align: center;
      margin: 16px 0 18px 0;
    }
    .doc-title h2 {
      font-size: 15px;
      font-weight: 900;
      text-decoration: underline;
      margin: 0 0 4px 0;
      color: #1a202c;
      letter-spacing: 0.8px;
    }
    .doc-title p {
      font-size: 12px;
      color: #4a5568;
      font-weight: 600;
      margin: 0;
    }
    .info-box {
      background-color: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 12px 16px;
      margin: 14px 0;
    }
    .info-table {
      width: 100%;
      border-collapse: collapse;
    }
    .info-table td {
      padding: 4px 0;
      font-size: 12px;
      vertical-align: top;
    }
    .info-label {
      width: 170px;
      color: #4a5568;
      font-weight: 500;
    }
    .info-sep {
      width: 15px;
      color: #718096;
    }
    .info-val {
      color: #1a202c;
      font-weight: 600;
    }
    .content-body {
      font-size: 12.5px;
      line-height: 1.65;
      margin: 14px 0;
      text-align: justify;
    }
    .footer-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 24px;
    }
    .qr-cell {
      vertical-align: bottom;
      text-align: left;
    }
    .sign-cell {
      vertical-align: bottom;
      text-align: center;
      width: 240px;
    }
    .verified-badge {
      display: inline-block;
      margin-left: 10px;
      border: 1.5px solid #c53030;
      color: #c53030;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 8px;
      font-weight: 900;
      text-align: center;
      letter-spacing: 0.8px;
      line-height: 1.2;
    }
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin: 16px 0;
    }
    .items-table th {
      background-color: #f1f5f9;
      color: #334155;
      font-size: 11px;
      font-weight: bold;
      text-transform: uppercase;
      padding: 8px 10px;
      border: 1px solid #cbd5e1;
      text-align: left;
    }
    .items-table td {
      padding: 8px 10px;
      font-size: 12px;
      border: 1px solid #e2e8f0;
    }
    .btn-print {
      display: inline-block;
      background: #00796b;
      color: white;
      padding: 10px 24px;
      border: none;
      border-radius: 8px;
      font-size: 13px;
      font-weight: bold;
      cursor: pointer;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .btn-print:hover {
      background: #004d40;
    }
  </style>
</head>
<body>
  <div class="no-print" style="text-align: center; margin-bottom: 20px; background: #e6fffa; padding: 12px; border-radius: 8px; border: 1px solid #b2f5ea;">
    <button class="btn-print" onclick="window.print()">Cetak Dokumen Sekarang (PDF / Printer)</button>
    <div style="font-size: 11px; color: #234e52; margin-top: 6px;">
      Jendela cetak browser otomatis terbuka. Anda dapat memilih printer fisik atau opsi "Simpan sebagai PDF".
    </div>
  </div>
  <div class="print-container">
    $htmlContent
  </div>
  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 350);
    };
  </script>
</body>
</html>
''';

  final blob = html.Blob([fullHtml], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
