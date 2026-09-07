/// CHỈ DÙNG TẠM lúc code/test - KHÔNG dùng trong bản chính thức.
///
/// Vì `session_provider.dart`/`login_screen.dart` (do bạn khác phụ trách)
/// chưa xong, chưa có cách nào đăng nhập thật để lấy accessToken. File này
/// giữ tạm 1 accessToken bạn tự lấy bằng tay (xem hướng dẫn ở README, mục
/// "Lấy token test tạm thời") để offer_screen/active_delivery_screen gọi
/// được API thật ngay bây giờ.
///
/// Khi SessionProvider thật xong, xoá file này và mọi chỗ đang dùng
/// DevTokenHolder.token, thay bằng SessionProvider.apiClient.
class DevTokenHolder {
  DevTokenHolder._();

  /// Dán accessToken (chuỗi JWT) lấy được từ bước đăng nhập bằng tay vào đây,
  /// hoặc nhập trực tiếp trong ô "Dán accessToken test" ở màn hình dev menu.
  static String? token;
}
