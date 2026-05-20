import 'package:flutter/material.dart';

/// Professional College ERP Design System - Color Palette
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2C5282); // Deep Professional Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A5F);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color secondaryLight = Color(0x1A10B981);
  
  // Accent Colors
  static const Color accent = Color(0xFFF97316); // Professional Orange
  static const Color accentLight = Color(0x1AF97316);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color background = Color(0xFFF8F9FA); // Off-white
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Light gray
  
  // Text Colors
  static const Color textDark = Color(0xFF1F2937); // Dark gray (primary text)
  static const Color textMedium = Color(0xFF374151); // Medium gray
  static const Color textLight = Color(0xFF4B5563); // Readable secondary text
  static const Color textMuted = Color(0xFF6B7280); // Subtle but visible
  
  // Border Colors
  static const Color border = Color(0xFFF0F1F3); // Very subtle, modern borderless feel
  static const Color borderLight = Color(0xFFF7F8F9);
  
  // Overlay Colors
  static Color overlay(Color color, double opacity) =>
      color.withValues(alpha: opacity);
  
  static Color primaryOverlay({double opacity = 0.1}) =>
      primary.withValues(alpha: opacity);
  static Color secondaryOverlay({double opacity = 0.1}) =>
      secondary.withValues(alpha: opacity);
  static Color errorOverlay({double opacity = 0.1}) =>
      error.withValues(alpha: opacity);
}
