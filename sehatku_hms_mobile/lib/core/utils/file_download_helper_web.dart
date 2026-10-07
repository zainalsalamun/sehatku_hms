// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileFromText({
  required String content,
  required String filename,
  String mimeType = 'text/csv;charset=utf-8',
}) {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
