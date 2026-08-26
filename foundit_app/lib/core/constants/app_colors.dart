import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (Clean, Modern Dark Theme)
  static const primary = Color(0xFF6366F1);      // Royal Indigo
  static const secondary = Color(0xFF8B5CF6);    // Violet Accent
  static const accent = Color(0xFF22D3EE);       // Cyan Accent
  static const yellow = Color(0xFFF59E0B);       // Sunny Amber

  // Backgrounds & Surfaces (Sleek Dark Palette)
  static const background = Color(0xFF0F1117);   // Dark Midnight
  static const surface = Color(0xFF1A1D2E);      // Dark Slate Surface
  static const surfaceLight = Color(0xFF242840); // Elevated Slate
  static const surfaceElevated = Color(0xFF242840); // Elevated Slate Alias
  static const card = Color(0xFF1E2235);         // Card Slate

  // Text Colors
  static const textPrimary = Color(0xFFF1F5F9);   // Off White
  static const textSecondary = Color(0xFF94A3B8); // Slate Secondary
  static const textMuted = Color(0xFF64748B);     // Muted Slate

  // Status Colors
  static const success = Color(0xFF22C55E);      // Bright Green
  static const warning = Color(0xFFF59E0B);      // Amber Yellow
  static const error = Color(0xFFEF4444);        // Crimson Red
  static const info = Color(0xFF3B82F6);         // Sky Blue

  // Borders & Dividers
  static const border = Color(0xFF2A2F45);
  static const borderLight = Color(0xFF3D4260);

  // Gradients
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static final cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
