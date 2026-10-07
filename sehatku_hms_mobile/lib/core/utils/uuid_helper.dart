import 'dart:math';

/// Utility to generate and validate standard RFC 4122 UUID version 4 strings
class UuidHelper {
  static final Random _random = Random.secure();

  /// Generates a standard random UUID v4 string (e.g. "f47ac10b-58cc-4372-a567-0e02b2c3d479")
  static String generate() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));

    // Set version to 4 (0100 in binary) in byte 6
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to 10xxxxxx in byte 8
    values[8] = (values[8] & 0x3f) | 0x80;

    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Checks if a string matches valid UUID regex format
  static bool isValid(String uuid) {
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(uuid);
  }
}
