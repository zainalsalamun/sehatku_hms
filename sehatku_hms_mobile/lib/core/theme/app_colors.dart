import 'package:flutter/material.dart';

/// Centralized Color Palette for SehatKu HMS
abstract final class AppColors {
  // Brand & Accent Colors
  static const primary = Color(0xFF087F8C);
  static const primaryLight = Color(0xFFE0F2F1);
  static const primaryDark = Color(0xFF055E68);
  static const secondary = Color(0xFF63C7B2);

  // Navy / Deep Brand
  static const navy = Color(0xFF123047);
  static const navyDark = Color(0xFF0D2131);
  static const navyLight = Color(0xFF1E3A8A);

  // Background & Surface
  static const background = Color(0xFFF5F8FA);
  static const surface = Colors.white;
  static const cardBackground = Colors.white;
  static const cardBorder = Color(0xFFE4EBEF);

  // Text Colors
  static const textPrimary = Color(0xFF123047);
  static const textSecondary = Color(0xFF405667);
  static const textMuted = Color(0xFF607585);
  static const textWhite = Colors.white;
  static final textWhite75 = Colors.white.withValues(alpha: 0.75);
  static final textWhite90 = Colors.white.withValues(alpha: 0.90);

  // Status Colors: Success / Checked-in / Terverifikasi / Lunas
  static const success = Color(0xFF25A271);
  static const successLight = Color(0xFFE8F5E9);
  static const successBorder = Color(0xFFA5D6A7);
  static const successText = Color(0xFF1B5E20);
  static const greenAccent = Color(0xFF69F0AE);

  // Status Colors: Warning / Pending / Menunggu / Antrean
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFF8E1);
  static const warningBorder = Color(0xFFFFE082);
  static const warningText = Color(0xFFE65100);
  static const amberAccent = Color(0xFFFFD740);
  static const star = Color(0xFFFFB800);

  // Status Colors: Info / Selesai / Terkonfirmasi / BPJS
  static const info = Color(0xFF0288D1);
  static const infoLight = Color(0xFFE1F5FE);
  static const infoBorder = Color(0xFF90CAF9);
  static const infoText = Color(0xFF0D47A1);

  // Status Colors: Error / Danger / Batal (Merah Hati / Deep Maroon)
  static const error = Color(0xFF8B1E2B); // Merah Hati utama
  static const errorLight = Color(0xFFFBF0F1); // Merah Hati muda / soft tint
  static const errorBorder = Color(0xFFE5A8AF); // Border Merah Hati lembut
  static const errorText = Color(0xFF6B111A); // Merah Hati gelap kontras tinggi
  static const maroon = Color(0xFF8B1E2B);
  static const maroonDark = Color(0xFF5B0E17);
  static const maroonLight = Color(0xFFFBF0F1);
  static const maroonBorder = Color(0xFFE5A8AF);

  // Insurance / BPJS Banner
  static const insuranceBg = Color(0xFFE6F4EA);
  static const insuranceBorder = Color(0xFFA5D6A7);
  static const insuranceIconBg = Color(0xFFC8E6C9);
  static const insuranceIcon = Color(0xFF2E7D32);

  // Neutrals & Grays
  static const grey50 = Color(0xFFF8FAFC);
  static const grey100 = Color(0xFFF1F5F9);
  static const grey200 = Color(0xFFE2E8F0);
  static const grey300 = Color(0xFFCBD5E1);
  static const grey400 = Color(0xFF94A3B8);
  static const grey600 = Color(0xFF64748B);
  static const grey700 = Color(0xFF475569);
  static const grey800 = Color(0xFF334155);

  // Interactive Overlays
  static final whiteOverlay15 = Colors.white.withValues(alpha: 0.15);
  static final whiteOverlay20 = Colors.white.withValues(alpha: 0.20);
  static final primaryOverlay10 = primary.withValues(alpha: 0.10);
  static final primaryOverlay12 = primary.withValues(alpha: 0.12);
  static final primaryOverlay15 = primary.withValues(alpha: 0.15);
  static final navyOverlay10 = navy.withValues(alpha: 0.10);
  static final navyOverlay20 = navy.withValues(alpha: 0.20);
  static final shadowColor = Colors.black.withValues(alpha: 0.04);
  static final bannerShadow = navy.withValues(alpha: 0.30);

  // Gradient Colors
  static const bannerGradient = [navy, navyLight];

  /// Status background color based on appointment/invoice status
  static Color getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return infoLight;
      case 'checked-in':
      case 'terkonfirmasi':
        return successLight;
      case 'batal':
      case 'dibatalkan':
        return errorLight;
      case 'menunggu':
      default:
        return warningLight;
    }
  }

  /// Status text/icon color based on appointment/invoice status
  static Color getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return infoText;
      case 'checked-in':
      case 'terkonfirmasi':
        return successText;
      case 'batal':
      case 'dibatalkan':
        return errorText;
      case 'menunggu':
      default:
        return warningText;
    }
  }
}
