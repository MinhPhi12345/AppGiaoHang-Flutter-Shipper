import 'package:flutter/foundation.dart';

/// KHUNG - chưa có logic thật, cần triển khai.
///
/// "Nguồn sự thật" duy nhất cho trạng thái đăng nhập trong toàn app
/// (dùng package `provider`, kiểu ChangeNotifier - gọi notifyListeners() khi
/// state đổi thì các màn hình đang lắng nghe sẽ tự build lại).
///
/// Cần có:
/// - Field: status (đã đăng nhập hay chưa), currentUser (AppUser?), errorMessage.
/// - restoreSession(): đọc token đã lưu lúc mở app, gọi AuthService.getMe() để
///   khôi phục phiên đăng nhập nếu còn hợp lệ.
/// - login(email, password): gọi AuthService.login, kiểm tra role phải là
///   DRIVER, lưu token qua SessionStore.
/// - logout(): gọi AuthService.logout rồi xoá token cục bộ.
class SessionProvider extends ChangeNotifier {
  // TODO: implement
}
