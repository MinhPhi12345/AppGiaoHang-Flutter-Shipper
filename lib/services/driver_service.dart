/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Gọi các API DriverService dành cho tài xế qua Gateway: /api/driver/me/...
/// (role DRIVER bắt buộc - ApiClient phải tự đính JWT).
/// Cần có các hàm (nhận ApiClient qua constructor):
/// - updateAvailability(DriverAvailability status) -> PATCH /api/driver/me/availability
/// - updateLocation({latitude, longitude, accuracyM}) -> PUT /api/driver/me/location
class DriverService {
  // TODO: implement
}
