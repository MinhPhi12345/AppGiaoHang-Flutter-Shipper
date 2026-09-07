/// Tương ứng RouteQuoteResponse bên MapService (POST /api/map/route/quote).
/// Dùng để hiển thị khoảng cách + thời gian ước tính giữa điểm lấy và điểm
/// giao, giúp tài xế ước lượng trước khi/đang giao (KHÔNG phải chỉ đường
/// từng bước - chỉ là số liệu tham khảo nhanh).
///
/// LƯU Ý: MapService hiện tính bằng công thức Haversine (đường thẳng chim
/// bay), KHÔNG phải khoảng cách đi thực tế theo đường bộ - xem field
/// [provider] để biết nguồn tính (ví dụ "HAVERSINE"). Vì vậy số phút/km chỉ
/// mang tính tham khảo, có thể ngắn hơn thực tế.
class RouteQuote {
  final double distanceKm;
  final double durationMin;
  final String provider;

  RouteQuote({
    required this.distanceKm,
    required this.durationMin,
    required this.provider,
  });

  factory RouteQuote.fromJson(Map<String, dynamic> json) => RouteQuote(
        distanceKm: double.tryParse(json['distanceKm']?.toString() ?? '') ?? 0,
        durationMin: double.tryParse(json['durationMin']?.toString() ?? '') ?? 0,
        provider: json['provider']?.toString() ?? '',
      );
}
