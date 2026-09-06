# App Giao Hàng - Shipper App (Flutter)

Frontend Flutter cho tài xế (shipper) trong hệ thống giao hàng microservices .NET.
Backend tương ứng: repo `AppGiaoHang-Dotnet-Microservice` (API Gateway + 7 service).

Repo này hiện chỉ có **khung project** (cấu trúc thư mục, tên class, chưa có
logic thật - đánh dấu `// TODO: implement`). Việc của cả nhóm là điền code
thật vào đúng từng file theo mô tả bên dưới.

## 1. Yêu cầu môi trường

- Flutter SDK (kênh stable) - chạy `flutter doctor`, sửa hết dòng `[!]`/`[X]`
  liên quan tới thiết bị bạn định chạy (Android/Chrome/Windows).
- VS Code + extension **Flutter** (tự kéo theo Dart).
- Backend phải đang chạy bằng Docker trước khi test app:
  ```bash
  # trong repo backend (AppGiaoHang-Dotnet-Microservice)
  docker compose up --build -d
  docker compose ps   # chờ tất cả "healthy"
  ```
  Gateway mặc định chạy ở `http://localhost:6200`.

## 2. Chạy project

```bash
git clone <URL_REPO_NAY>
cd flutter_app
flutter pub get
flutter devices        # xem thiết bị nào đang sẵn sàng
flutter run -d <device-id>
```

### Địa chỉ Gateway theo nơi chạy app

Cấu hình tại `lib/core/app_config.dart`. Backend luôn chạy cổng 6200 trên máy
bạn, nhưng địa chỉ GỌI TỚI nó khác nhau tuỳ nơi app đang chạy:

| Chạy trên | Base URL |
|---|---|
| Windows desktop / Chrome (cùng máy chạy Docker) | `http://localhost:6200` |
| Android emulator | `http://10.0.2.2:6200` |
| Điện thoại Android thật (cùng wifi với máy chạy Docker) | `http://<IP-LAN-cua-may>:6200` |

### Tài khoản test có sẵn (dev seed từ backend)

```text
driver@deliveryapp.local / Driver123!
```

## 3. Cấu trúc thư mục

```text
lib/
  main.dart           # Điểm khởi động app + màn hình "Danh sách màn hình (dev)"
                       # để mở nhanh từng screen trong lúc code.
  core/                # Hạ tầng dùng chung, không chứa nghiệp vụ cụ thể.
    app_config.dart      # Base URL của API Gateway theo từng nền tảng.
    api_client.dart      # Nơi DUY NHẤT gọi http.get/post/put/patch, tự thêm
                         # header Authorization, tự parse lỗi backend.
    api_exception.dart   # Kiểu lỗi thống nhất, khớp {code, message, details}.
    session_store.dart   # Lưu/đọc/xoá accessToken + refreshToken (mã hoá).
  models/              # Kiểu dữ liệu khớp response JSON của backend.
    user.dart            # UserResponse (IdentityService)
    auth_tokens.dart      # TokenResponse (IdentityService)
    driver_profile.dart  # DriverProfileResponse + enum DriverAvailability
    delivery_offer.dart  # DeliveryOfferResponse (lời mời nhận đơn)
    delivery.dart         # DeliveryResponse (chuyến giao hàng đã nhận)
    paged_response.dart  # PagedResponse<T> dùng chung
  services/            # Một class = một nhóm API, chỉ gọi qua ApiClient.
    auth_service.dart    # /api/identity/...
    driver_service.dart  # /api/driver/me/...
    delivery_service.dart # /api/delivery/...
  state/               # ChangeNotifier (package `provider`) giữ state toàn app.
    session_provider.dart   # Đăng nhập/đăng xuất, thông tin user hiện tại.
    delivery_provider.dart  # Bật/tắt nhận đơn, offers, chuyến đang giao.
  theme/
    app_theme.dart       # Màu sắc/ThemeData dùng chung - sửa 1 chỗ, áp toàn app.
  widgets/             # Widget tái sử dụng giữa nhiều màn hình.
    primary_button.dart, status_badge.dart, loading_view.dart, error_view.dart
  screens/             # Mỗi màn hình = 1 file, chỉ dùng service/state ở trên,
                       # không tự gọi http trực tiếp.
    login_screen.dart
    home_screen.dart
    offer_screen.dart
    active_delivery_screen.dart
    order_detail_screen.dart
    profile_screen.dart
```

Nguyên tắc luồng dữ liệu (1 chiều, để khỏi rối khi 4 người cùng sửa):

```text
screens/  ->  state/ (Provider)  ->  services/  ->  core/api_client.dart  ->  Gateway
   ^ chỉ hiển thị UI + gọi Provider        ^ chỉ chứa nghiệp vụ, không build widget
```

Màn hình KHÔNG được tự `http.get(...)` hay tự parse JSON - luôn đi qua
Provider -> Service -> ApiClient.

## 4. API Gateway - endpoint cần dùng cho app tài xế

Tất cả gọi qua Gateway `http://<base>` + đường dẫn dưới đây, không gọi thẳng
tới từng service (cổng 6201-6207 chỉ dùng nội bộ giữa các service).

| Method | Path | Dùng ở | Ghi chú |
|---|---|---|---|
| POST | `/api/identity/register` | auth_service | Tài khoản mới luôn role CUSTOMER |
| POST | `/api/identity/login` | auth_service | Trả accessToken/refreshToken |
| POST | `/api/identity/refresh` | auth_service | Làm mới accessToken |
| POST | `/api/identity/logout` | auth_service | Thu hồi refreshToken |
| GET | `/api/identity/me` | auth_service | Lấy role - phải là `DRIVER` mới cho vào app |
| PATCH | `/api/driver/me/availability` | driver_service | Bật/tắt sẵn sàng nhận đơn |
| PUT | `/api/driver/me/location` | driver_service | Gửi GPS định kỳ |
| GET | `/api/delivery/offers/me` | delivery_service | Danh sách lời mời đang chờ |
| POST | `/api/delivery/offers/{offerId}/accept` | delivery_service | Nhận đơn |
| POST | `/api/delivery/offers/{offerId}/reject` | delivery_service | Từ chối |
| POST | `/api/delivery/{deliveryId}/pickup` | delivery_service | Xác nhận đã lấy hàng |
| POST | `/api/delivery/{deliveryId}/start` | delivery_service | Bắt đầu giao |
| POST | `/api/delivery/{deliveryId}/complete` | delivery_service | Hoàn tất |
| GET | `/api/delivery/order/{orderId}` | delivery_service | Xem chi tiết theo orderId |

Lỗi backend luôn có dạng `{ "code": "...", "message": "...", "details": null }`
- `ApiException` nên parse đúng 3 field này để hiển thị `message` lên UI.

**Giới hạn cần biết:** hiện chưa có API kiểu `GET /api/driver/me` để lấy lại
chuyến đang phụ trách khi mở app lại giữa chừng lúc đang giao hàng - nếu cần,
báo nhóm backend bổ sung, hoặc tạm thời chấp nhận giới hạn này ở bản đầu.

## 5. Quy ước làm việc nhóm

- Giữ nhánh `main` luôn build được. Mỗi người làm một nhánh riêng theo màn
  hình/khu vực, ví dụ `feature/login-screen`, `feature/delivery-provider`,
  rồi tạo Pull Request để merge - tránh 4 người cùng sửa `main.dart` một lúc.
- Không gọi `package:http` trực tiếp trong `screens/` - luôn qua
  `state/` -> `services/` -> `core/api_client.dart`.
- Comment/tên biến có thể viết tiếng Việt cho dễ hiểu, miễn nhất quán.
- Trước khi push, chạy `flutter analyze` và `flutter test` để chắc code không
  vỡ cấu trúc chung.
