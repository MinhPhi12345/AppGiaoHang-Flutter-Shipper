import 'package:flutter/material.dart';

/// KHUNG - màu mặc định tạm thời, chỉnh lại theo đúng màu/Figma của nhóm.
/// Đây là nơi DUY NHẤT nên định nghĩa màu sắc dùng chung toàn app.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1565C0); // TODO: đổi theo Figma

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primary,
      );
}
