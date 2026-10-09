import 'package:flutter/foundation.dart';

void printHtmlDocument({
  required String title,
  required String htmlContent,
}) {
  debugPrint('[PrintHelper] Print requested for "$title" on native/stub environment.');
}
