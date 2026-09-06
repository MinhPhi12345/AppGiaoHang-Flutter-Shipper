import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Nơi CHỈ MỘT chỗ duy nhất định nghĩa địa chỉ API Gateway.
///
/// Vì sao cần file này: Gateway luôn chạy ở cổng 6200 trên máy bạn (xem README
/// backend), nhưng "địa chỉ để app gọi tới" lại khác nhau tuỳ nơi app đang chạy:
///   - Chạy trên Windows desktop / Chrome (cùng máy đang chạy Docker): localhost
///   - Chạy trên Android emulator: 10.0.2.2 (địa chỉ đặc biệt trỏ ngược ra máy host)
///   - Chạy trên điện thoại thật: phải là IP LAN thật của máy bạn (vd 192.168.1.5)
class AppConfig {
  AppConfig._();

  /// Đổi IP này thành IP LAN thật của máy bạn khi test trên điện thoại thật
  /// (xem bằng lệnh `ipconfig` trên Windows, tìm dòng IPv4 Address).
  static const String _lanIp = '192.168.1.5';

  static const int gatewayPort = 6200;

  /// true khi chạy `flutter run --dart-define=REAL_DEVICE=true` (test trên
  /// điện thoại Android thật thay vì emulator, mặc định là false).
  static const bool _isRealAndroidDevice =
      bool.fromEnvironment('REAL_DEVICE', defaultValue: false);

  /// Base URL đầy đủ, ví dụ: http://localhost:6200
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$gatewayPort';
    }
    if (Platform.isAndroid) {
      return _isRealAndroidDevice
          ? 'http://$_lanIp:$gatewayPort'
          : 'http://10.0.2.2:$gatewayPort';
    }
    // iOS simulator, Windows desktop, macOS... đều dùng chung máy host.
    return 'http://localhost:$gatewayPort';
  }
}
