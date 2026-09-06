/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Gọi các API DeliveryService dành cho tài xế qua Gateway: /api/delivery/...
/// Cần có các hàm (nhận ApiClient qua constructor):
/// - getMyOffers({page, pageSize})        -> GET  /api/delivery/offers/me
/// - acceptOffer(offerId)                 -> POST /api/delivery/offers/{offerId}/accept
/// - rejectOffer(offerId, {reasonCode})   -> POST /api/delivery/offers/{offerId}/reject
/// - confirmPickup(deliveryId)            -> POST /api/delivery/{deliveryId}/pickup
/// - startDelivering(deliveryId)          -> POST /api/delivery/{deliveryId}/start
/// - completeDelivery(deliveryId)         -> POST /api/delivery/{deliveryId}/complete
/// - getByOrderId(orderId)                -> GET  /api/delivery/order/{orderId}
class DeliveryService {
  // TODO: implement
}
