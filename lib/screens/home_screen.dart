import 'package:flutter/material.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
/// Màn hình chính sau đăng nhập: bật/tắt nhận đơn (DeliveryProvider) + danh
/// sách offer đang chờ, dẫn sang OfferScreen / ActiveDeliveryScreen / ProfileScreen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ tài xế')),
      body: const Center(child: Text('TODO: danh sách offer + trạng thái nhận đơn')),
    );
  }
}
