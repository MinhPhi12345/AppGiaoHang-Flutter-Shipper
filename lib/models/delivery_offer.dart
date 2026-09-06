/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Tương ứng DeliveryOfferResponse bên DeliveryService - một lời mời nhận đơn
/// gửi cho tài xế, có hạn trả lời (expiresAt). Lưu ý: số điện thoại người
/// nhận CHƯA có trong offer, chỉ có sau khi accept (xem Delivery bên dưới).
///
/// Cần có field: offerId, deliveryId, orderId, pickupAddress, dropoffAddress,
/// distanceToPickupKm, radiusKm, status, expiresAt, sentAt, incomeEstimate.
/// Nên có factory `fromJson(...)`.
class DeliveryOffer {
  // TODO: implement
}
