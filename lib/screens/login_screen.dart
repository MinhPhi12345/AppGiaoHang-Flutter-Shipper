import 'package:flutter/material.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
/// Màn hình đăng nhập. Sẽ cần: form email/password, gọi
/// SessionProvider.login(), hiển thị lỗi nếu sai role/sai mật khẩu.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: const Center(child: Text('TODO: form đăng nhập')),
    );
  }
}
