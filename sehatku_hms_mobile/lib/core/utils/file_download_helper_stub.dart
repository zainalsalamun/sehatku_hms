import 'package:flutter/foundation.dart';

void downloadFileFromText({
  required String content,
  required String filename,
  String mimeType = 'text/csv;charset=utf-8',
}) {
  debugPrint('[FileDownloadHelper Stub] Download requested for $filename (Length: ${content.length} chars)');
}
