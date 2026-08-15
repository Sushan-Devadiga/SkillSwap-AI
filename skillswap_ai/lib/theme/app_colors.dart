import 'package:flutter/material.dart';

class AppColors {
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFD0DBED);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE9FC);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F6);
  static const Color onSurface = Color(0xFF121C2A);
  static const Color onSurfaceVariant = Color(0xFF3C4A42);
  static const Color inverseSurface = Color(0xFF27313F);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color outline = Color(0xFF6C7A71);
  static const Color outlineVariant = Color(0xFFBBCABF);
  static const Color primary = Color(0xFF006C49);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimaryContainer = Color(0xFF00422B);
  static const Color inversePrimary = Color(0xFF4EDEA3);
  static const Color secondary = Color(0xFF006B5F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF6DF5E1);
  static const Color onSecondaryContainer = Color(0xFF006F64);
  static const Color tertiary = Color(0xFF00687A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF00B2D0);
  static const Color onTertiaryContainer = Color(0xFF003F4B);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primaryFixed = Color(0xFF6FFBBE);
  static const Color primaryFixedDim = Color(0xFF4EDEA3);
  static const Color onPrimaryFixed = Color(0xFF002113);
  static const Color onPrimaryFixedVariant = Color(0xFF005236);
  static const Color secondaryFixed = Color(0xFF71F8E4);
  static const Color secondaryFixedDim = Color(0xFF4FDBC8);
  static const Color onSecondaryFixed = Color(0xFF00201C);
  static const Color onSecondaryFixedVariant = Color(0xFF005048);
  static const Color tertiaryFixed = Color(0xFFACEDFF);
  static const Color tertiaryFixedDim = Color(0xFF4CD7F6);
  static const Color onTertiaryFixed = Color(0xFF001F26);
  static const Color onTertiaryFixedVariant = Color(0xFF004E5C);
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF121C2A);
  static const Color surfaceVariant = Color(0xFFD9E3F6);
  static const Color surfaceBg = Color(0xFFF9FAFB);
  static const Color surfaceStroke = Color(0xFFE5E7EB);
  
  // Need to represent AI Glow using a Shader or LinearGradient in widgets
  // ai-glow: 'linear-gradient(135deg, #10B981 0%, #14B8A6 50%, #06B6D4 100%)'
  static const LinearGradient aiGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
