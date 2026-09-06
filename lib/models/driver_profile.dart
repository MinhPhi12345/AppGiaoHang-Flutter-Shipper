/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Tương ứng enum DriverStatus bên DriverService: OFFLINE, AVAILABLE, BUSY
/// (backend gửi/nhận dạng chuỗi, ví dụ "AVAILABLE").
enum DriverAvailability { offline, available, busy }

/// Tương ứng DriverProfileResponse bên DriverService.
/// Cần có field: driverId, availabilityStatus, activeDeliveryId (String?), updatedAt.
/// Nên có factory `fromJson(Map<String, dynamic> json)`.
class DriverProfile {
  // TODO: implement
}
