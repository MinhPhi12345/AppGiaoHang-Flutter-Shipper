import '../core/api_client.dart';
import '../models/delivery.dart';
import '../models/delivery_offer.dart';
import '../models/paged_response.dart';

/// Gọi các API của DeliveryService dành cho tài xế, qua Gateway:
/// /api/delivery/... (route thật xác nhận trong ApiGateway/appsettings.json
/// và DeliveryController.cs bên backend).
class DeliveryService {
  final ApiClient _client;
  DeliveryService(this._client);

  /// GET /api/delivery/offers/me?page=&pageSize=
  Future<PagedResponse<DeliveryOffer>> getMyOffers({int page = 1, int pageSize = 20}) async {
    final json = await _client.get(
      '/api/delivery/offers/me',
      query: {'page': page, 'pageSize': pageSize},
    );
    return PagedResponse.fromJson(json as Map<String, dynamic>, DeliveryOffer.fromJson);
  }

  /// POST /api/delivery/offers/{offerId}/accept
  /// Trả về {offerId, deliveryId, status} - dùng deliveryId/orderId của offer
  /// gốc để gọi tiếp getByOrderId lấy chi tiết đầy đủ.
  Future<Map<String, dynamic>> acceptOffer(String offerId) async {
    final json = await _client.post('/api/delivery/offers/$offerId/accept');
    return json as Map<String, dynamic>;
  }

  /// POST /api/delivery/offers/{offerId}/reject
  Future<void> rejectOffer(String offerId, {String reasonCode = 'DRIVER_DECLINED'}) async {
    await _client.post(
      '/api/delivery/offers/$offerId/reject',
      body: {'reasonCode': reasonCode},
    );
  }

  /// POST /api/delivery/{deliveryId}/pickup - tài xế xác nhận đã lấy hàng.
  /// (ASSIGNED -> PICKED_UP, theo đúng ChangeDriverStageAsync bên backend)
  Future<Delivery> confirmPickup(String deliveryId) async {
    final json = await _client.post('/api/delivery/$deliveryId/pickup');
    return Delivery.fromJson(json as Map<String, dynamic>);
  }

  /// POST /api/delivery/{deliveryId}/start - bắt đầu giao.
  /// (PICKED_UP -> DELIVERING)
  Future<Delivery> startDelivering(String deliveryId) async {
    final json = await _client.post('/api/delivery/$deliveryId/start');
    return Delivery.fromJson(json as Map<String, dynamic>);
  }

  /// POST /api/delivery/{deliveryId}/complete - hoàn tất.
  /// (DELIVERING -> COMPLETED)
  Future<Delivery> completeDelivery(String deliveryId) async {
    final json = await _client.post('/api/delivery/$deliveryId/complete');
    return Delivery.fromJson(json as Map<String, dynamic>);
  }

  /// GET /api/delivery/order/{orderId} - xem chi tiết delivery theo orderId.
  Future<Delivery> getByOrderId(String orderId) async {
    final json = await _client.get('/api/delivery/order/$orderId');
    return Delivery.fromJson(json as Map<String, dynamic>);
  }
}
