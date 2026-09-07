import '../core/api_client.dart';
import '../models/route_quote.dart';

/// Gọi MapService qua Gateway: POST /api/map/route/quote.
/// (Route này mới được thêm vào ApiGateway/appsettings.json - trước đó
/// MapService chưa được lộ ra ngoài cho app dùng, chỉ dùng nội bộ giữa các
/// service. Đã trao đổi thêm route + 4 field lat/lng trong DeliveryResponse
/// để màn hình ActiveDeliveryScreen có thể hiển thị khoảng cách/thời gian
/// ước tính - xem README mục "Dữ liệu bổ sung từ backend".)
class MapService {
  final ApiClient _client;
  MapService(this._client);

  /// Trả về khoảng cách (km) + thời gian ước tính (phút) giữa 2 điểm.
  Future<RouteQuote> getRouteQuote({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
  }) async {
    final json = await _client.post(
      '/api/map/route/quote',
      body: {
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'dropoffLatitude': dropoffLatitude,
        'dropoffLongitude': dropoffLongitude,
      },
    );
    return RouteQuote.fromJson(json as Map<String, dynamic>);
  }
}
