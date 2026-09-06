import 'package:flutter/material.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
/// Chuyến giao hàng đang thực hiện: hiển thị địa chỉ lấy/giao, số điện thoại
/// người nhận, nút chuyển bước (lấy hàng -> bắt đầu giao -> hoàn tất) gọi
/// DeliveryProvider.advanceStage(), và nút mở bản đồ ngoài (url_launcher).
class ActiveDeliveryScreen extends StatelessWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đang giao hàng')),
      body: const Center(child: Text('TODO: chi tiết chuyến giao + nút chuyển bước')),
    );
  }
}
