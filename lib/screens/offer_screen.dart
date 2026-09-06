import 'package:flutter/material.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
/// Chi tiết một lời mời nhận đơn, có đếm ngược tới expiresAt, nút Nhận/Từ chối
/// gọi DeliveryProvider.acceptOffer()/rejectOffer().
class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lời mời nhận đơn')),
      body: const Center(child: Text('TODO: chi tiết offer + nút nhận/từ chối')),
    );
  }
}
