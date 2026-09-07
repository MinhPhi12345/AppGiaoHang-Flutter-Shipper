import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/device_location.dart';
import '../models/delivery.dart';
import '../models/delivery_offer.dart';
import '../models/route_quote.dart';
import '../services/delivery_service.dart';
import '../services/map_service.dart';

/// Quản lý nghiệp vụ "đang làm việc" của tài xế liên quan tới nhận đơn và
/// giao hàng: danh sách offer đang chờ, và chuyến giao hàng đang thực hiện.
///
/// (Chưa xử lý bật/tắt "sẵn sàng nhận đơn" - phần đó thuộc DriverService/
/// HomeScreen, ngoài phạm vi offer_screen/active_delivery_screen.)
class DeliveryProvider extends ChangeNotifier {
  final DeliveryService _deliveryService;
  final MapService _mapService;

  DeliveryProvider(ApiClient apiClient)
      : _deliveryService = DeliveryService(apiClient),
        _mapService = MapService(apiClient);

  List<DeliveryOffer> offers = [];
  bool isLoadingOffers = false;
  String? offersError;

  /// Chuyến đang phụ trách (null nếu tài xế đang rảnh, chưa nhận đơn nào).
  Delivery? activeDelivery;
  bool isLoadingActiveDelivery = false;

  /// Khoảng cách + thời gian ước tính từ VỊ TRÍ HIỆN TẠI của tài xế (GPS
  /// thật, qua DeviceLocation) tới điểm của BƯỚC ĐANG LÀM (điểm lấy hàng nếu
  /// đang ASSIGNED, điểm giao hàng nếu đã PICKED_UP/DELIVERING) - xem
  /// [_loadRouteQuote]. null nếu chưa tải/lỗi/không lấy được vị trí (xem
  /// routeError để biết lý do cụ thể hiển thị cho người dùng).
  RouteQuote? routeQuote;
  bool isLoadingRoute = false;
  String? routeError;

  /// Toạ độ GPS thật của tài xế TẠI THỜI ĐIỂM tải [routeQuote] gần nhất -
  /// dùng chung cho MiniMapPreview (vẽ chấm/icon tài xế) và cho nút "Mở
  /// Google Maps" (làm điểm xuất phát rõ ràng, xem ActiveDeliveryScreen.
  /// _openMap) thay vì mỗi chỗ tự xin định vị riêng. null khi chưa tải/
  /// không lấy được vị trí (xem [routeError]).
  double? driverLatitude;
  double? driverLongitude;

  Future<void> loadOffers() async {
    isLoadingOffers = true;
    offersError = null;
    notifyListeners();
    try {
      final paged = await _deliveryService.getMyOffers();
      offers = paged.items;
    } on ApiException catch (e) {
      offersError = e.message;
    } finally {
      isLoadingOffers = false;
      notifyListeners();
    }
  }

  /// Trả về null nếu thành công, hoặc thông báo lỗi để màn hình hiển thị.
  Future<String?> acceptOffer(DeliveryOffer offer) async {
    try {
      await _deliveryService.acceptOffer(offer.offerId);
      offers.removeWhere((o) => o.offerId == offer.offerId);
      activeDelivery = await _deliveryService.getByOrderId(offer.orderId);
      notifyListeners();
      unawaited(_loadRouteQuote());
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> rejectOffer(DeliveryOffer offer, {String reasonCode = 'DRIVER_DECLINED'}) async {
    try {
      await _deliveryService.rejectOffer(offer.offerId, reasonCode: reasonCode);
      offers.removeWhere((o) => o.offerId == offer.offerId);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Tải chuyến giao hàng theo orderId - dùng khi mở lại ActiveDeliveryScreen
  /// (ví dụ từ Home) hoặc lúc test tay (xem dev menu trong main.dart) khi
  /// chưa đi qua đúng luồng nhận offer.
  Future<String?> loadActiveDeliveryByOrderId(String orderId) async {
    isLoadingActiveDelivery = true;
    notifyListeners();
    try {
      activeDelivery = await _deliveryService.getByOrderId(orderId);
      unawaited(_loadRouteQuote());
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isLoadingActiveDelivery = false;
      notifyListeners();
    }
  }

  Future<String?> refreshActiveDelivery() async {
    if (activeDelivery == null) return null;
    try {
      activeDelivery = await _deliveryService.getByOrderId(activeDelivery!.orderId);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Chuyển sang bước tiếp theo, dựa theo status hiện tại của activeDelivery:
  /// ASSIGNED -(pickup)-> PICKED_UP -(start)-> DELIVERING -(complete)-> COMPLETED
  /// Đúng 3 thao tác tài xế được phép làm (khớp DeliveryWorkflowService bên backend).
  Future<String?> advanceStage() async {
    final delivery = activeDelivery;
    if (delivery == null) return 'Chưa có chuyến giao nào đang hoạt động.';
    try {
      switch (delivery.status) {
        case 'ASSIGNED':
          activeDelivery = await _deliveryService.confirmPickup(delivery.deliveryId);
          break;
        case 'PICKED_UP':
          activeDelivery = await _deliveryService.startDelivering(delivery.deliveryId);
          break;
        case 'DELIVERING':
          activeDelivery = await _deliveryService.completeDelivery(delivery.deliveryId);
          break;
        default:
          return 'Chuyến giao đang ở trạng thái ${delivery.status}, không có hành động tiếp theo.';
      }
      if (activeDelivery!.status == 'COMPLETED') {
        activeDelivery = null; // Xong chuyến - tài xế quay lại nhận đơn mới.
        routeQuote = null;
        routeError = null;
        driverLatitude = null;
        driverLongitude = null;
      } else {
        unawaited(_loadRouteQuote()); // Đổi bước -> đổi điểm đến, tính lại.
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Toạ độ tài xế cần đi tới, tuỳ theo bước hiện tại của [delivery] - đúng
  /// với những gì ActiveDeliveryScreen đang hiển thị (targetAddress). Trả về
  /// null khi đã COMPLETED/CANCELLED - không còn điểm nào cần ước tính nữa.
  static (double lat, double lng)? _targetForStage(Delivery delivery) {
    switch (delivery.status) {
      case 'ASSIGNED':
        return (delivery.pickupLatitude, delivery.pickupLongitude);
      case 'PICKED_UP':
      case 'DELIVERING':
        return (delivery.dropoffLatitude, delivery.dropoffLongitude);
      default:
        return null;
    }
  }

  /// Thử tải lại vị trí GPS + khoảng cách/thời gian ước tính (gọi lại
  /// [_loadRouteQuote]) - dùng khi lần tải trước bị lỗi (ví dụ tài xế quên
  /// bật định vị/chưa cấp quyền) và muốn thử lại NGAY mà không cần thoát ra
  /// vào lại màn hình (trước đây phải khởi động lại cả app vì routeError
  /// chỉ được tải 1 lần lúc nhận đơn/đổi bước, không có cách tải lại thủ
  /// công). Public để ActiveDeliveryScreen gọi từ nút "Thử lại" trên
  /// MiniMapPreview và từ didChangeAppLifecycleState (tự thử lại khi app
  /// quay lại foreground, ví dụ sau khi tài xế vừa bật định vị trong Cài
  /// đặt máy rồi quay lại app).
  Future<void> retryDriverLocation() => _loadRouteQuote();

  /// Lấy vị trí GPS thật của tài xế (DeviceLocation), rồi gọi MapService
  /// tính khoảng cách/thời gian ước tính TỪ ĐÓ tới điểm của bước hiện tại
  /// (không phải khoảng cách cố định lấy<->giao của cả đơn nữa). Chạy nền
  /// (không chặn UI) - lỗi/không lấy được vị trí chỉ ghi vào routeError để
  /// màn hình hiển thị nhẹ, KHÔNG âm thầm hiện số liệu sai (ví dụ lùi về
  /// khoảng cách lấy<->giao) khi không có vị trí thật.
  Future<void> _loadRouteQuote() async {
    final delivery = activeDelivery;
    if (delivery == null) return;
    final target = _targetForStage(delivery);
    if (target == null) {
      routeQuote = null;
      routeError = null;
      notifyListeners();
      return;
    }
    isLoadingRoute = true;
    routeError = null;
    notifyListeners();
    try {
      final position = await DeviceLocation.getCurrentPosition();
      if (position == null) {
        routeQuote = null;
        driverLatitude = null;
        driverLongitude = null;
        routeError = 'Không lấy được vị trí hiện tại - hãy cho phép quyền vị '
            'trí trên trình duyệt/thiết bị để xem khoảng cách chính xác.';
        return;
      }
      driverLatitude = position.latitude;
      driverLongitude = position.longitude;
      routeQuote = await _mapService.getRouteQuote(
        pickupLatitude: position.latitude,
        pickupLongitude: position.longitude,
        dropoffLatitude: target.$1,
        dropoffLongitude: target.$2,
      );
    } on ApiException catch (e) {
      routeQuote = null;
      routeError = e.message;
    } finally {
      isLoadingRoute = false;
      notifyListeners();
    }
  }
}
