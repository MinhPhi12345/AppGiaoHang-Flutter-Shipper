import 'package:flutter/material.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
/// Xem chi tiết một đơn/chuyến giao theo orderId, gọi
/// DeliveryService.getByOrderId() (đọc, không thao tác trạng thái ở đây).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: const Center(child: Text('TODO: chi tiết đơn hàng')),
    );
  }
}
