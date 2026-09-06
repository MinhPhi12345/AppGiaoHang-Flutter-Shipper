/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Tương ứng DeliveryResponse bên DeliveryService - trạng thái đầy đủ của
/// một chuyến giao hàng đã được tài xế nhận.
/// Vòng đời status: ASSIGNED -> PICKED_UP -> DELIVERING -> COMPLETED
/// (có thể rẽ nhánh CANCELLED).
///
/// Cần có field: deliveryId, orderId, customerId, driverId, pickupAddress,
/// dropoffAddress, receiverPhone, status, totalFee, assignedAt, pickedUpAt,
/// deliveringAt, completedAt, cancelledAt.
/// Nên có factory `fromJson(...)`.
class Delivery {
  // TODO: implement
}
