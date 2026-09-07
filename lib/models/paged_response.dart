/// Tương ứng `PagedResponse<T>` dùng chung ở backend:
///   { "page": 1, "pageSize": 20, "totalItems": 5, "items": [...] }
class PagedResponse<T> {
  final int page;
  final int pageSize;
  final int totalItems;
  final List<T> items;

  PagedResponse({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.items,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    return PagedResponse<T>(
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? rawItems.length,
      totalItems: json['totalItems'] ?? rawItems.length,
      items: rawItems.map((e) => itemParser(e as Map<String, dynamic>)).toList(),
    );
  }
}
