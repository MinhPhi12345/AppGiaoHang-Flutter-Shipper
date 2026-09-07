import 'package:flutter/material.dart';

/// Bảng màu ước lượng theo ảnh thiết kế bạn gửi (tông xanh lá/mint) - chỉnh
/// lại cho khớp mã màu chính xác nếu nhóm có file Figma.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1B8A5A); // xanh lá đậm (nút, icon nhấn)
  static const Color primaryLight = Color(0xFFDFF3E8); // nền mint nhạt (khu vực trên)
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF8A8F98);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
