import 'package:flutter/material.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
/// Hồ sơ tài xế: hiển thị AppUser (GET /api/identity/me) + nút đăng xuất
/// (SessionProvider.logout()).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: const Center(child: Text('TODO: thông tin tài xế + đăng xuất')),
    );
  }
}
