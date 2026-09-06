import 'package:flutter/foundation.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Quản lý nghiệp vụ "đang làm việc" của tài xế: bật/tắt nhận đơn, danh sách
/// offer đang chờ, và chuyến giao hàng đang thực hiện (nếu có).
///
/// Cần có:
/// - Field: availability, offers (`List<DeliveryOffer>`), activeDelivery (Delivery?).
/// - toggleAvailability(): gọi DriverService.updateAvailability.
/// - loadOffers(): gọi DeliveryService.getMyOffers.
/// - acceptOffer(offer) / rejectOffer(offer): gọi DeliveryService tương ứng.
/// - advanceStage(): dựa vào activeDelivery.status hiện tại để gọi đúng bước
///   tiếp theo (pickup -> start -> complete).
/// - sendLocation(lat, lng): gọi DriverService.updateLocation.
class DeliveryProvider extends ChangeNotifier {
  // TODO: implement
}
