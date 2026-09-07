import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/delivery_offer.dart';
import '../state/delivery_provider.dart';
import '../theme/app_theme.dart';
import 'active_delivery_screen.dart';

/// Danh sách các lời mời nhận đơn đang chờ tài xế trả lời (dữ liệu thật từ
/// GET /api/delivery/offers/me qua DeliveryProvider.offers). Mỗi lời mời có
/// hạn trả lời (expiresAt) - hết hạn thì backend tự coi như từ chối, nên màn
/// hình có đếm ngược và tự ẩn nút khi hết hạn.
///
/// Tự động tải lại danh sách mỗi 5 giây khi màn hình đang mở (polling đơn
/// giản, CHƯA có push/WebSocket) để không bỏ lỡ lời mời mới trong lúc đang
/// xem màn hình này.
class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  Timer? _pollTimer;
  Timer? _tickTimer;
  final Set<String> _busyOfferIds = {};

  @override
  void initState() {
    super.initState();
    // Tải ngay lần đầu, không đợi 5s.
    context.read<DeliveryProvider>().loadOffers();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<DeliveryProvider>().loadOffers();
    });
    // Timer riêng chỉ để vẽ lại đồng hồ đếm ngược mỗi giây, không gọi mạng.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _accept(DeliveryOffer offer) async {
    setState(() => _busyOfferIds.add(offer.offerId));
    final error = await context.read<DeliveryProvider>().acceptOffer(offer);
    if (!mounted) return;
    setState(() => _busyOfferIds.remove(offer.offerId));
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
    );
  }

  Future<void> _reject(DeliveryOffer offer) async {
    setState(() => _busyOfferIds.add(offer.offerId));
    final error = await context.read<DeliveryProvider>().rejectOffer(offer);
    if (!mounted) return;
    setState(() => _busyOfferIds.remove(offer.offerId));
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      appBar: AppBar(title: const Text('Lời mời nhận đơn'), backgroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: () => context.read<DeliveryProvider>().loadOffers(),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(DeliveryProvider provider) {
    if (provider.isLoadingOffers && provider.offers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.offersError != null && provider.offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.offersError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<DeliveryProvider>().loadOffers(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.offers.isEmpty) {
      return ListView(
        // Bọc trong ListView (thay vì Center) để RefreshIndicator vẫn kéo được.
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Chưa có lời mời nào.\nĐang tự động kiểm tra lại mỗi 5 giây...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.offers.length,
      itemBuilder: (context, index) => _OfferCard(
        offer: provider.offers[index],
        isBusy: _busyOfferIds.contains(provider.offers[index].offerId),
        onAccept: () => _accept(provider.offers[index]),
        onReject: () => _reject(provider.offers[index]),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final DeliveryOffer offer;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferCard({
    required this.offer,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');
    final expired = offer.isExpired;
    final secondsLeft = offer.timeLeft.inSeconds.clamp(0, 999);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${money.format(offer.incomeEstimate)} đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                _CountdownChip(secondsLeft: secondsLeft, expired: expired),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${offer.distanceToPickupKm.toStringAsFixed(1)} km tới điểm lấy hàng',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const Divider(height: 20),
            _AddressLine(icon: Icons.storefront_outlined, label: 'Lấy', address: offer.pickupAddress),
            const SizedBox(height: 6),
            _AddressLine(icon: Icons.flag_outlined, label: 'Giao', address: offer.dropoffAddress),
            const SizedBox(height: 16),
            if (expired)
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Đã hết hạn', style: TextStyle(color: AppTheme.textMuted)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy ? null : onReject,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isBusy ? null : onAccept,
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Nhận đơn'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  const _AddressLine({required this.icon, required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: address),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final int secondsLeft;
  final bool expired;
  const _CountdownChip({required this.secondsLeft, required this.expired});

  @override
  Widget build(BuildContext context) {
    final urgent = !expired && secondsLeft <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: expired
            ? Colors.grey.shade200
            : (urgent ? Colors.red.shade50 : AppTheme.primaryLight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        expired ? 'Hết hạn' : 'Còn ${secondsLeft}s',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: expired ? AppTheme.textMuted : (urgent ? Colors.red : AppTheme.primary),
        ),
      ),
    );
  }
}
