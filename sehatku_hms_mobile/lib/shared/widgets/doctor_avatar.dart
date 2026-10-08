import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/config/app_env.dart';
import '../../core/theme/app_theme.dart';

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.photoUrl,
    this.name = '',
    this.radius = 20,
    this.borderWidth = 0,
    this.borderColor,
  });

  final String photoUrl;
  final String name;
  final double radius;
  final double borderWidth;
  final Color? borderColor;

  Widget _buildFallback() {
    final initials = name.trim().replaceAll('dr. ', '').replaceAll('drg. ', '');
    final initialChar = initials.isNotEmpty ? initials.substring(0, 1).toUpperCase() : '';

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: AppTheme.navy.withValues(alpha: 0.12),
      child: Center(
        child: initialChar.isNotEmpty
            ? Text(
                initialChar,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.85,
                  color: AppTheme.navy,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: radius * 1.1,
                color: AppTheme.navy,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl.trim();
    Widget imageWidget;

    if (trimmed.startsWith('data:image/')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (_) {
        imageWidget = _buildFallback();
      }
    } else if (trimmed.isNotEmpty) {
      final resolvedUrl = AppEnv.resolveMediaUrl(trimmed);
      imageWidget = Image.network(
        resolvedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
    }

    final avatar = ClipOval(child: imageWidget);

    if (borderWidth > 0) {
      return Container(
        width: radius * 2 + borderWidth * 2,
        height: radius * 2 + borderWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.primary,
            width: borderWidth,
          ),
        ),
        child: ClipOval(child: avatar),
      );
    }

    return avatar;
  }
}
