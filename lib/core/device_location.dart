import 'package:geolocator/geolocator.dart';

/// Lấy vị trí GPS THẬT của thiết bị đang chạy app - dùng để tính khoảng
/// cách/thời gian ước tính từ tài xế tới điểm lấy/giao hàng (thay vì chỉ
/// tính cố định giữa 2 địa chỉ của đơn, xem DeliveryProvider._loadRouteQuote).
///
/// Trả về null nếu không lấy được (dịch vụ vị trí đang tắt, người dùng từ
/// chối cấp quyền, hết thời gian chờ...) - nơi gọi PHẢI tự xử lý trường hợp
/// null (hiển thị thông báo, không được giả định luôn có vị trí).
///
/// Trên Flutter Web: trình duyệt sẽ tự hiện popup xin quyền vị trí ở lần gọi
/// đầu tiên - chỉ hoạt động trên `localhost`/HTTPS (secure context), khớp
/// với cách chạy dev hiện tại (`flutter run -d chrome`).
class DeviceLocation {
  DeviceLocation._();

  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Bất kỳ lỗi nào (plugin lỗi, timeout, không hỗ trợ nền tảng...) đều
      // coi như "không lấy được vị trí" - không để lỗi này làm crash màn
      // hình chính (xem/đổi trạng thái đơn vẫn phải hoạt động bình thường).
      return null;
    }
  }
}
