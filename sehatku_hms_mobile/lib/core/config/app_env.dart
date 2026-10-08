import 'package:flutter/foundation.dart';

/// Centralized Environment Configuration for SehatKu HMS
/// Supports compile-time environment variables via `--dart-define`
/// Example:
/// `flutter run --dart-define=API_BASE_URL=https://api.sehatku.id/api/v1`
/// `flutter run --dart-define=SERVER_ORIGIN=https://api.sehatku.id`
abstract final class AppEnv {
  /// Base API URL configurable via `--dart-define=API_BASE_URL=...`
  static const String _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

  /// Server origin URL configurable via `--dart-define=SERVER_ORIGIN=...`
  static const String _serverOriginDefine = String.fromEnvironment('SERVER_ORIGIN');

  /// Dynamic server origin (host + port)
  static String get serverOrigin {
    if (_serverOriginDefine.isNotEmpty) {
      return _serverOriginDefine.endsWith('/')
          ? _serverOriginDefine.substring(0, _serverOriginDefine.length - 1)
          : _serverOriginDefine;
    }

    if (_apiBaseUrlDefine.isNotEmpty) {
      final uri = Uri.tryParse(_apiBaseUrlDefine);
      if (uri != null && uri.hasScheme && uri.hasAuthority) {
        return '${uri.scheme}://${uri.authority}';
      }
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    // For Android Emulator, localhost is mapped to 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    // iOS Simulator, macOS Desktop, Windows, Linux
    return 'http://localhost:3000';
  }

  /// Base API URL (e.g. http://localhost:3000/api/v1)
  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) {
      return _apiBaseUrlDefine;
    }
    return '$serverOrigin/api/v1';
  }

  /// Helper to safely resolve media and asset URLs from the backend database
  static String resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    var trimmed = path.trim();

    // Remap localhost or 127.0.0.1 to Android Emulator host 10.0.2.2 when running on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (trimmed.contains('localhost:3000')) {
        trimmed = trimmed.replaceAll('localhost:3000', '10.0.2.2:3000');
      } else if (trimmed.contains('127.0.0.1:3000')) {
        trimmed = trimmed.replaceAll('127.0.0.1:3000', '10.0.2.2:3000');
      }
    }

    if (trimmed.startsWith('data:image/') ||
        trimmed.startsWith('blob:') ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$serverOrigin$trimmed';
    }
    return '$serverOrigin/$trimmed';
  }
}
