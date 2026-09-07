/// Tương ứng DeliveryResponse bên DeliveryService - trạng thái đầy đủ của
/// một chuyến giao hàng mà tài xế đang phụ trách (sau khi đã accept offer).
///
/// Vòng đời status (xác nhận từ code thật DeliveryWorkflowService.
/// ChangeDriverStageAsync - chỉ đúng 3 thao tác tài xế được làm):
///   ASSIGNED --(pickup)--> PICKED_UP --(start)--> DELIVERING --(complete)--> COMPLETED
/// (có thể rẽ nhánh CANCELLED trước khi lấy hàng).
///
/// LƯU Ý QUAN TRỌNG (giới hạn dữ liệu hiện tại của backend):
/// - ĐÃ có latitude/longitude của điểm lấy/giao hàng (pickupLatitude/
///   pickupLongitude/dropoffLatitude/dropoffLongitude) - backend mới bổ
///   sung 4 field này vào DeliveryResponse (trước đó entity có lưu nhưng
///   response chưa lộ ra). Dùng để gọi MapService lấy khoảng cách/thời gian
///   ước tính (xem services/map_service.dart) - CHƯA dùng để vẽ bản đồ nhúng
///   thật (mini_map_preview.dart vẫn là khung, để làm sau nếu cần).
/// - CHƯA có tên người nhận, chỉ có receiverPhone (số điện thoại). Nếu cần
///   hiển thị tên người nhận, cũng cần xin backend bổ sung field.
class Delivery {
  final String deliveryId;
  final String orderId;
  final String customerId;
  final String? driverId;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String? receiverPhone; // null trước khi accept, có giá trị sau khi accept
  final String status; // ASSIGNED | PICKED_UP | DELIVERING | COMPLETED | CANCELLED
  final int totalFee; // VNĐ
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveringAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  Delivery({
    required this.deliveryId,
    required this.orderId,
    required this.customerId,
    required this.driverId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.receiverPhone,
    required this.status,
    required this.totalFee,
    required this.assignedAt,
    required this.pickedUpAt,
    required this.deliveringAt,
    required this.completedAt,
    required this.cancelledAt,
  });

  static DateTime? _parseDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  /// Thời điểm cập nhật gần nhất, dựa trên các mốc thời gian có thật mà
  /// DeliveryResponse trả về (KHÔNG có field updatedAt riêng trong response
  /// thật - chỉ suy ra từ mốc mới nhất trong số các cột *_At đã có).
  DateTime get lastUpdatedAt {
    final candidates = [completedAt, cancelledAt, deliveringAt, pickedUpAt, assignedAt]
        .whereType<DateTime>();
    return candidates.isEmpty ? DateTime.now() : candidates.first;
  }

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        deliveryId: json['deliveryId'].toString(),
        orderId: json['orderId'].toString(),
        customerId: json['customerId']?.toString() ?? '',
        driverId: json['driverId']?.toString(),
        pickupAddress: json['pickupAddress']?.toString() ?? '',
        dropoffAddress: json['dropoffAddress']?.toString() ?? '',
        pickupLatitude: double.tryParse(json['pickupLatitude']?.toString() ?? '') ?? 0,
        pickupLongitude: double.tryParse(json['pickupLongitude']?.toString() ?? '') ?? 0,
        dropoffLatitude: double.tryParse(json['dropoffLatitude']?.toString() ?? '') ?? 0,
        dropoffLongitude: double.tryParse(json['dropoffLongitude']?.toString() ?? '') ?? 0,
        receiverPhone: json['receiverPhone']?.toString(),
        status: json['status']?.toString() ?? '',
        totalFee: int.tryParse(json['totalFee']?.toString() ?? '') ?? 0,
        assignedAt: _parseDate(json['assignedAt']),
        pickedUpAt: _parseDate(json['pickedUpAt']),
        deliveringAt: _parseDate(json['deliveringAt']),
        completedAt: _parseDate(json['completedAt']),
        cancelledAt: _parseDate(json['cancelledAt']),
      );
}
