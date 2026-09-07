/// Tương ứng DeliveryOfferResponse bên DeliveryService - một "lời mời" nhận
/// đơn gửi cho tài xế, có hạn trả lời (expiresAt). Số điện thoại người nhận
/// CHƯA xuất hiện ở offer (chỉ có sau khi accept, xem model Delivery) - đúng
/// theo thiết kế bảo mật thật của backend.
class DeliveryOffer {
  final String offerId;
  final String deliveryId;
  final String orderId;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceToPickupKm;
  final double radiusKm;
  final String status;
  final DateTime expiresAt;
  final DateTime sentAt;
  final int incomeEstimate;

  DeliveryOffer({
    required this.offerId,
    required this.deliveryId,
    required this.orderId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceToPickupKm,
    required this.radiusKm,
    required this.status,
    required this.expiresAt,
    required this.sentAt,
    required this.incomeEstimate,
  });

  Duration get timeLeft => expiresAt.difference(DateTime.now());
  bool get isExpired => timeLeft.isNegative;

  factory DeliveryOffer.fromJson(Map<String, dynamic> json) => DeliveryOffer(
        offerId: json['offerId'].toString(),
        deliveryId: json['deliveryId'].toString(),
        orderId: json['orderId'].toString(),
        pickupAddress: json['pickupAddress']?.toString() ?? '',
        dropoffAddress: json['dropoffAddress']?.toString() ?? '',
        distanceToPickupKm:
            double.tryParse(json['distanceToPickupKm']?.toString() ?? '') ?? 0,
        radiusKm: double.tryParse(json['radiusKm']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? '',
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
        sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
        incomeEstimate: int.tryParse(json['incomeEstimate']?.toString() ?? '') ?? 0,
      );
}
