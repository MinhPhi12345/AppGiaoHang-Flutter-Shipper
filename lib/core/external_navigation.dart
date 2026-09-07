import 'package:url_launcher/url_launcher.dart';

/// Mở app Google Maps CÓ SẴN trên điện thoại để tài xế tự dẫn đường - không
/// nhúng bản đồ/không dẫn đường trong app này. Chỉ là mở 1 đường link, nên
/// KHÔNG cần API key hay tài khoản Google Cloud gì cả.
class ExternalNavigation {
  ExternalNavigation._();

  /// Mở Google Maps chỉ đường TỚI 1 toạ độ, có thể chỉ định rõ điểm XUẤT
  /// PHÁT (ví dụ vị trí GPS hiện tại của tài xế, lấy qua DeviceLocation) thay
  /// vì để Google Maps tự đoán - quan trọng khi tài xế đang ở bước ASSIGNED
  /// (cần chỉ đường TỪ VỊ TRÍ HIỆN TẠI ĐẾN điểm lấy hàng, KHÔNG PHẢI từ điểm
  /// lấy đến điểm giao) hay PICKED_UP/DELIVERING (từ vị trí hiện tại đến
  /// điểm giao hàng).
  ///
  /// Nếu không truyền [originLatitude]/[originLongitude] (null), Google Maps
  /// sẽ tự dùng vị trí hiện tại của thiết bị làm điểm xuất phát (hành vi mặc
  /// định của Google Maps khi URL không có tham số `origin`) - dùng làm
  /// phương án dự phòng khi chưa lấy được GPS thật trong app.
  static Future<bool> openDirections({
    required double destinationLatitude,
    required double destinationLongitude,
    double? originLatitude,
    double? originLongitude,
  }) {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$destinationLatitude,$destinationLongitude',
      'travelmode': 'driving',
      if (originLatitude != null && originLongitude != null)
        'origin': '$originLatitude,$originLongitude',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Mở Google Maps chỉ đường tới 1 địa chỉ dạng chữ, ví dụ "1 Lê Lợi, Quận 1".
  ///
  /// Chỉ còn dùng cho những chỗ CHƯA có toạ độ sẵn (ví dụ nếu sau này có màn
  /// hình khác chỉ có địa chỉ dạng chữ) - ở ActiveDeliveryScreen/
  /// OrderDetailScreen giờ đã có latitude/longitude thật từ backend nên ưu
  /// tiên dùng [openDirections] ở trên, chính xác hơn địa chỉ dạng chữ.
  static Future<bool> openAddress(String address) {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': address,
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Mở app gọi điện thoại tới số [phone].
  static Future<bool> callPhone(String phone) {
    return launchUrl(Uri(scheme: 'tel', path: phone));
  }
}
