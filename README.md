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

### Chạy lại lần sau (đã setup rồi, chỉ mở máy lên tiếp tục làm)

1. Mở Docker Desktop (chỉ cần mở app).
2. `cd` vào repo backend, chạy `docker-compose up -d` (không cần `--build` nếu
   không có sửa code backend từ lần build gần nhất - khởi động nhanh hơn
   nhiều). Nếu lần trước dừng bằng `docker-compose stop` thì dùng
   `docker-compose start` còn nhanh hơn nữa. Chỉ thêm `--build` khi có sửa
   file `.cs`/`appsettings*.json` bên backend.
3. `docker-compose ps` - chờ tất cả `healthy`.
4. `cd` vào `flutter_app`, chạy `flutter run -d <device>` như cũ.
5. JWT token cũ chắc đã hết hạn (mặc định 60 phút) - login lại qua Postman
   lấy token mới, dán vào dev menu của app.


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
    external_navigation.dart # Mở app Google Maps có sẵn trên máy để chỉ đường
                         # (chỉ mở link, không cần API key/thẻ tín dụng).
    device_location.dart # Lấy vị trí GPS thật của thiết bị (package geolocator).
  models/              # Kiểu dữ liệu khớp response JSON của backend.
    user.dart            # UserResponse (IdentityService)
    auth_tokens.dart      # TokenResponse (IdentityService)
    driver_profile.dart  # DriverProfileResponse + enum DriverAvailability
    delivery_offer.dart  # DeliveryOfferResponse (lời mời nhận đơn)
    delivery.dart         # DeliveryResponse (chuyến giao hàng đã nhận)
    route_quote.dart     # RouteQuoteResponse (MapService) - khoảng cách/thời gian ước tính
    paged_response.dart  # PagedResponse<T> dùng chung
  services/            # Một class = một nhóm API, chỉ gọi qua ApiClient.
    auth_service.dart    # /api/identity/...
    driver_service.dart  # /api/driver/me/...
    delivery_service.dart # /api/delivery/...
    map_service.dart     # /api/map/route/quote
  state/               # ChangeNotifier (package `provider`) giữ state toàn app.
    session_provider.dart   # Đăng nhập/đăng xuất, thông tin user hiện tại.
    delivery_provider.dart  # Bật/tắt nhận đơn, offers, chuyến đang giao.
  theme/
    app_theme.dart       # Màu sắc/ThemeData dùng chung - sửa 1 chỗ, áp toàn app.
  widgets/             # Widget tái sử dụng giữa nhiều màn hình.
    primary_button.dart, status_badge.dart, loading_view.dart, error_view.dart
    mini_map_preview.dart # Đã code thật - bản đồ xem trước (MapLibre +
                         # OpenFreeMap) hiển thị vị trí GPS tài xế + điểm
                         # lấy/giao hàng, dùng ở ActiveDeliveryScreen.
  screens/             # Mỗi màn hình = 1 file, chỉ dùng service/state ở trên,
                       # không tự gọi http trực tiếp.
    login_screen.dart          # KHUNG
    home_screen.dart           # KHUNG
    offer_screen.dart          # Đã code thật - xem mục 5
    active_delivery_screen.dart # Đã code thật - xem mục 5
    order_detail_screen.dart   # Đã code thật - xem mục 5
    profile_screen.dart        # KHUNG
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
| POST | `/api/map/route/quote` | delivery_service (qua map_service.dart) | Khoảng cách (km) + thời gian ước tính (phút) giữa 2 toạ độ - route này do frontend mới thêm vào Gateway, xem ghi chú dưới |

Lỗi backend luôn có dạng `{ "code": "...", "message": "...", "details": null }`
- `ApiException` nên parse đúng 3 field này để hiển thị `message` lên UI.

**Giới hạn cần biết (đã xác nhận từ code thật của backend, không phải đoán):**
- Chưa có API kiểu `GET /api/driver/me` để lấy lại chuyến đang phụ trách khi
  mở app lại giữa chừng lúc đang giao hàng.
- `DeliveryResponse` chỉ có `receiverPhone` (số điện thoại người nhận), CHƯA
  có tên người nhận.

Cả 2 điểm trên nên báo nhóm backend (DeliveryService) bổ sung sớm nếu cần
dùng - đây là việc phụ thuộc nhóm khác, không tự làm được.

**Đã sửa (không còn là giới hạn nữa):**
- `DeliveryResponse` giờ ĐÃ trả toạ độ (`pickupLatitude`/`pickupLongitude`/
  `dropoffLatitude`/`dropoffLongitude`) - mình đã tự thêm 4 field này vào
  `DeliveryService/Contracts/DeliveryWorkflowContracts.cs` và mapper
  `ToResponse` trong `DeliveryWorkflowService.cs` (dữ liệu đã có sẵn trong DB,
  chỉ là response chưa lộ ra). **Nhớ báo nhóm backend về thay đổi này khi họ
  pull code**, để tránh conflict/hiểu lầm khi merge.
- Route `POST /api/map/route/quote` trước đây CHƯA được khai báo trong
  `ApiGateway/appsettings.json` (MapService có endpoint này nhưng chỉ dùng
  nội bộ, gateway không route ra ngoài) - mình đã thêm route + cluster `map`
  vào file đó để app gọi được qua Gateway.

## 5. 3 màn hình đã code thật: OfferScreen, ActiveDeliveryScreen, OrderDetailScreen

**Đã code thật (không còn là khung nữa):** `lib/screens/offer_screen.dart`,
`lib/screens/active_delivery_screen.dart`, `lib/screens/order_detail_screen.dart`,
`lib/state/delivery_provider.dart`, `lib/services/delivery_service.dart`,
`lib/services/map_service.dart`, `lib/models/delivery.dart`,
`lib/models/delivery_offer.dart`, `lib/models/route_quote.dart`,
`lib/core/api_client.dart`, `lib/core/api_exception.dart`,
`lib/core/external_navigation.dart`. Các phần khác (login, home, session,
driver_service, profile...) VẪN CÒN LÀ KHUNG, chưa đụng tới.

**Luồng 3 màn hình này khớp với nhau như sau:**

```text
OfferScreen (danh sách lời mời)
  --bấm "Nhận đơn"--> DeliveryProvider.acceptOffer() --> ActiveDeliveryScreen
                                                              |
                                                    bấm tiêu đề / icon biên nhận
                                                              v
                                                        OrderDetailScreen
```

- **OfferScreen**: danh sách lời mời đang chờ (`GET /api/delivery/offers/me`),
  tự tải lại mỗi 5 giây (polling đơn giản, chưa có push/WebSocket) để không bỏ
  lỡ lời mời mới, có đếm ngược tới `expiresAt` từng lời mời. Nhận đơn xong tự
  chuyển sang `ActiveDeliveryScreen` (`pushReplacement`, không cho back về
  offer cũ vì offer đó đã accept rồi).
- **ActiveDeliveryScreen**: tập trung vào bước ĐANG làm (chỉ hiện địa chỉ của
  bước hiện tại + nút trượt xác nhận), tránh dài dòng khi tài xế đang lái xe.
- **OrderDetailScreen**: xem TOÀN BỘ thông tin đơn (cả 2 địa chỉ lấy/giao,
  cước phí, lịch sử thời gian từng bước) - KHÔNG có hành động đổi trạng thái,
  chỉ để xem lại. Mở từ `ActiveDeliveryScreen` bằng cách bấm vào tiêu đề
  "Đơn #..." ở đầu màn hình hoặc icon biên nhận (📄) cạnh đó. Nhận `Delivery`
  qua constructor (không tự gọi API) nên tái dùng được cho việc khác sau này
  (ví dụ lịch sử đơn cũ), không phụ thuộc cứng vào `DeliveryProvider.activeDelivery`.

**Cách đổi trạng thái (ở ActiveDeliveryScreen):** tài xế TRƯỢT nút ở cuối màn hình (package
`slide_to_act`, kiểu Grab/ShopeeFood) thay vì bấm nút thường - tránh bấm nhầm
lúc đang cầm hàng/lái xe. Đúng 3 thao tác tài xế được phép làm (xác nhận từ
code thật `DeliveryWorkflowService.ChangeDriverStageAsync` bên backend, không
phải tự đặt ra):

```text
ASSIGNED --(pickup)--> PICKED_UP --(start)--> DELIVERING --(complete)--> COMPLETED
```

Nhãn nút trượt tự đổi theo `delivery.status` hiện tại; hoàn tất xong
(COMPLETED) thì tự đóng màn hình và quay lại màn trước.

**Nút "Mở Google Maps":** dùng toạ độ thật (KHÔNG còn dùng địa chỉ dạng chữ
nữa) qua `ExternalNavigation.openDirections` (`core/external_navigation.dart`)
- luôn truyền RÕ điểm xuất phát là vị trí GPS hiện tại của tài xế
(`DeliveryProvider.driverLatitude`/`driverLongitude`) và điểm đến là toạ độ
của bước đang làm, KHÔNG để Google Maps tự đoán điểm xuất phát. Quan trọng:
đây là lý do khi đang ASSIGNED, bấm nút này sẽ chỉ đường TỪ VỊ TRÍ HIỆN TẠI
ĐẾN điểm lấy hàng (không phải từ điểm lấy đến điểm giao) - đúng ý đồ ban đầu.
Không cần API key/thẻ tín dụng (chỉ mở 1 đường link
`https://www.google.com/maps/dir/?api=1&destination=<lat,lng>&origin=<lat,lng>`).

**Khoảng cách + thời gian ước tính:** ngay dưới địa chỉ điểm lấy/giao có 1
thẻ nhỏ hiển thị "Còn X km • ~Y phút". Tính TỪ VỊ TRÍ GPS THẬT của tài xế
(qua `lib/core/device_location.dart`, dùng package `geolocator`) TỚI điểm
của bước đang làm (điểm lấy nếu đang `ASSIGNED`, điểm giao nếu đã
`PICKED_UP`/`DELIVERING`) - gọi `MapService` (`POST /api/map/route/quote`)
qua `lib/services/map_service.dart`. Tự tính lại mỗi khi có `activeDelivery`
mới HOẶC mỗi lần đổi bước (`DeliveryProvider._loadRouteQuote`, gọi lại trong
cả `acceptOffer`/`loadActiveDeliveryByOrderId`/`advanceStage`).

Lưu ý:
- Đây là số liệu tính theo đường thẳng (Haversine, xem
  `MapService/Services/HaversineDistanceCalculator.cs` bên backend), KHÔNG
  phải khoảng cách đi thực tế theo đường bộ (không tính đường một chiều, kẹt
  xe...) - chỉ mang tính tham khảo nhanh.
- Nếu trình duyệt/thiết bị chưa cấp quyền vị trí (hoặc tắt GPS), thẻ sẽ hiện
  thông báo lỗi xin quyền thay vì số liệu sai - KHÔNG âm thầm lùi về cách
  tính cũ (khoảng cách cố định lấy<->giao của cả đơn) vì cách đó đã gây hiểu
  lầm là "khoảng cách tới điểm hiện tại" trong lúc thực ra không phải.
- Trên Flutter Web, trình duyệt sẽ tự hiện popup xin quyền vị trí ở lần đầu
  mở màn hình - chỉ hoạt động trên `localhost`/HTTPS (secure context).

**Đã làm (không còn là khung nữa):** bản đồ nhúng xem trước
(`lib/widgets/mini_map_preview.dart`) hiển thị ở đầu ActiveDeliveryScreen,
dùng `maplibre_gl` (vector tile MapLibre) + `OpenFreeMap`
(https://openfreemap.org, style `bright` - phong cách màu kiểu OpenStreetMap
cổ điển) làm nguồn bản đồ - hoàn toàn miễn phí, không cần API key/thẻ tín
dụng, không giới hạn request. Widget ghim 2 ICON (không phải chấm tròn đơn
giản nữa): icon xe máy màu xanh dương là vị trí GPS hiện tại của tài xế,
icon ghim vị trí màu xanh lá là điểm đích của bước đang làm (điểm lấy khi
ASSIGNED, điểm giao khi PICKED_UP/DELIVERING), tự zoom camera cho vừa cả 2
điểm - 2 icon này được vẽ (rasterize) từ Material Icons thành ảnh PNG lúc
chạy (`_rasterizeIcon`) vì maplibre_gl chỉ nhận ảnh bitmap làm marker, không
nhận IconData trực tiếp. Widget KHÔNG tự xin định vị - dùng lại đúng toạ độ
GPS mà `DeliveryProvider` đã tải cho phần "khoảng cách/thời gian ước tính"
bên dưới (tránh xin quyền vị trí 2 lần, tránh 2 số liệu lệch nhau). Bấm "Mở
Google Maps" bên dưới vẫn dùng để chỉ đường thật từng bước - bản đồ nhúng
này chỉ để xem nhanh, không thay thế.

**Phóng to bản đồ, ẩn bớt thông tin:** có 1 icon (góc trên-phải bản đồ) để
bật/tắt chế độ "phóng to" - khi bật, bản đồ chiếm gần hết màn hình, phần chi
tiết (thẻ ước tính, người nhận, lịch sử trạng thái, nút Google Maps) được ẩn
đi, chỉ giữ lại tiêu đề bước hiện tại + nút trượt xác nhận (để vẫn thao tác
được bình thường). Bấm lại icon đó để quay về giao diện đầy đủ. Đây chỉ là
state hiển thị cục bộ của màn hình (`_isMapFocused`), không ảnh hưởng dữ
liệu.

Lưu ý khi build/chạy:
- `maplibre_gl` CHỈ hỗ trợ Android/iOS/Web, KHÔNG hỗ trợ Windows/macOS/Linux
  desktop - test bằng `flutter run -d chrome` hoặc thiết bị/máy ảo Android,
  KHÔNG dùng `flutter run -d windows` (sẽ lỗi build).
- Sau khi pull code có thay đổi này, nhớ chạy lại `flutter pub get` để tải
  package `maplibre_gl` mới.
- 2 package cũ `flutter_map`/`latlong2` (dự tính dùng ban đầu) đã được thay
  bằng `maplibre_gl` và xoá khỏi `pubspec.yaml`.

## 6. Test tạm không cần đăng nhập thật (dev token)

Vì `login_screen`/`session_provider` (do bạn khác phụ trách) chưa xong, để
test `offer_screen`/`active_delivery_screen` với backend thật ngay bây giờ,
dùng cách tạm sau (xoá đi khi có đăng nhập thật):

1. Đảm bảo backend đang chạy (`docker compose up --build -d` bên repo
   backend), lấy accessToken bằng cách gọi thử API login - ví dụ bằng
   PowerShell:
   ```powershell
   $login = Invoke-RestMethod -Method Post -Uri http://localhost:6200/api/identity/login `
     -ContentType 'application/json' `
     -Body '{"email":"driver@deliveryapp.local","password":"Driver123!"}'
   $login.accessToken   # copy chuỗi này
   ```
   (hoặc dùng Postman - xem `postman/DeliveryApp-Group2.postman_collection.json`
   bên repo backend).
2. Chạy app (`flutter run`), ở màn hình "Danh sách màn hình (dev)" đầu tiên,
   dán accessToken vừa copy vào ô "accessToken (JWT)", bấm "Lưu token".
3. Đặt sẵn 1 delivery ở trạng thái ASSIGNED cho tài xế này (ví dụ tạo đơn
   bằng tài khoản CUSTOMER, đợi tài xế được match/tự accept qua Postman),
   lấy orderId, dán vào ô "orderId (GUID)", bấm "Tải chuyến & mở Đang giao
   hàng" - sẽ mở thẳng `ActiveDeliveryScreen` với dữ liệu thật.

Token chỉ lưu trong bộ nhớ (`lib/core/dev_token_holder.dart`), mất khi tắt
app - phải dán lại mỗi lần mở app mới trong lúc code.

## 7. Quy ước làm việc nhóm

- Giữ nhánh `main` luôn build được. Mỗi người làm một nhánh riêng theo màn
  hình/khu vực, ví dụ `feature/login-screen`, `feature/delivery-provider`,
  rồi tạo Pull Request để merge - tránh 4 người cùng sửa `main.dart` một lúc.
- Không gọi `package:http` trực tiếp trong `screens/` - luôn qua
  `state/` -> `services/` -> `core/api_client.dart`.
- Comment/tên biến có thể viết tiếng Việt cho dễ hiểu, miễn nhất quán.
- Trước khi push, chạy `flutter analyze` và `flutter test` để chắc code không
  vỡ cấu trúc chung.
