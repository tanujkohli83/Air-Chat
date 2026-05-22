import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const accent = Color(0xFF8B5CF6);
  static const background = Color(0xFFF9FAFB);
  static const chatBackground = Color(0xFF111827);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3F4F6);
  static const surfaceAlt = Color(0xFFEFF1F7);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const recipientBubble = Color(0xFFE5E7EB);
  static const recipientBubbleDark = Color(0xFF1F2937);
  static const recipientText = Color(0xFF111827);
  static const senderText = Colors.white;
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
}

class AppGradients {
  static const indigoViolet = LinearGradient(
    colors: [AppColors.primary, AppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const deepChat = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1F2937)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
