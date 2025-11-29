import 'package:flutter/material.dart';

/// App color palette based on specified design system
/// Primary Light: #E8F9FD, Primary: #79DAE8, Primary Dark: #0AA1DD, Accent: #2155CD
class AppColors {
  // Primary Colors
  static const Color primaryLight = Color(0xFFE8F9FD); // rgb(232, 249, 253)
  static const Color primary = Color(0xFF79DAE8); // rgb(121, 218, 232)
  static const Color primaryDark = Color(0xFF0AA1DD); // rgb(10, 161, 221)
  static const Color accent = Color(0xFF2155CD); // rgb(33, 85, 205)

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF9CA3AF);

  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Disabled Colors
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);
}
