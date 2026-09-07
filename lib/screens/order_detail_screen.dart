import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/external_navigation.dart';
import '../models/delivery.dart';
import '../models/route_quote.dart';
import '../theme/app_theme.dart';

/// Xem chi tiết đầy đủ một chuyến giao (địa chỉ lấy VÀ giao cùng lúc, cước
/// phí, lịch sử thời gian từng bước) - khác với ActiveDeliveryScreen là màn
/// hình đó chỉ tập trung vào bước ĐANG làm (để trượt xác nhận), còn màn này
/// là xem lại toàn bộ thông tin đơn, không có hành động đổi trạng thái.
///
/// Nhận [delivery] qua constructor (không tự gọi API/đọc DeliveryProvider)
/// để màn hình này dùng lại được cho cả chuyến đang hoạt động (mở từ
/// ActiveDeliveryScreen) và sau này cho lịch sử đơn cũ nếu cần - không giả
/// định đây luôn là activeDelivery của provider.
///
/// Nền màn hình dùng riêng [_backgroundColor] (xanh mint nhạt) thay vì nền
/// trắng mặc định của Scaffold - các card thông tin (giá, địa chỉ, người
/// nhận, lịch sử) đặt nền TRẮNG rõ ràng để nổi bật trên nền mint đó, riêng
/// card "Trạng thái hiện tại" giữ tông mint đậm hơn 1 chút để làm điểm nhấn.
class OrderDetailScreen extends StatelessWidget {
  final Delivery delivery;

  /// Khoảng cách/thời gian ước tính (nếu nơi gọi đã có sẵn, ví dụ lấy từ
  /// DeliveryProvider.routeQuote) - truyền vào để hiển thị lại, không tự gọi
  /// MapService ở đây để tránh gọi lại API không cần thiết.
  final RouteQuote? routeQuote;

  const OrderDetailScreen({super.key, required this.delivery, this.routeQuote});

  /// Nền trang - mint rất nhạt, nhạt hơn [_statusCardColor] một chút để 2
  /// card khác nhau vẫn phân biệt được với nhau và với nền.
  static const Color _backgroundColor = Color(0xFFEEF4EF);

  /// Nền riêng cho card "Trạng thái hiện tại" - mint đậm hơn nền trang để
  /// nổi bật lên như một điểm nhấn (khớp màu AppTheme.primaryLight đã dùng
  /// ở IconButton "gọi người nhận" bên dưới, giữ nhất quán trong cùng màn).
  static const Color _statusCardColor = AppTheme.primaryLight;

  Future<void> _openMap(BuildContext context, String address) async {
    final ok = await ExternalNavigation.openAddress(address);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps trên máy này.')),
      );
    }
  }

  Future<void> _callReceiver(BuildContext context, String phone) async {
    final ok = await ExternalNavigation.callPhone(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng gọi điện.')),
      );
    }
  }

  static (String, Color) _statusInfo(String status) {
    switch (status) {
      case 'ASSIGNED':
        return ('Đã nhận đơn', AppTheme.primary);
      case 'PICKED_UP':
        return ('Đã lấy hàng', AppTheme.primary);
      case 'DELIVERING':
        return ('Đang giao', AppTheme.primary);
      case 'COMPLETED':
        return ('Đã hoàn tất', Colors.green);
      case 'CANCELLED':
        return ('Đã huỷ', Colors.red);
      default:
        return (status, AppTheme.textMuted);
    }
  }

  /// Câu mô tả ngắn cho trạng thái hiện tại - giúp shipper hiểu nhanh đơn
  /// đang ở đâu trong quy trình mà không cần tra lại toàn bộ lịch sử thời
  /// gian bên dưới. Khớp đúng 5 trạng thái thật từ backend (xem _statusInfo
  /// và doc comment DeliveryWorkflowService bên ActiveDeliveryScreen).
  static String _statusDescription(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 'Bạn đã nhận đơn này - hãy di chuyển đến điểm lấy hàng.';
      case 'PICKED_UP':
        return 'Đã lấy hàng thành công - đang trên đường đến điểm giao.';
      case 'DELIVERING':
        return 'Đang giao hàng - xác nhận hoàn tất khi đã đến nơi giao.';
      case 'COMPLETED':
        return 'Đơn đã giao thành công, chuyến đã kết thúc.';
      case 'CANCELLED':
        return 'Đơn này đã bị huỷ, không cần xử lý thêm.';
      default:
        return 'Không xác định được trạng thái đơn.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');
    final (statusLabel, statusColor) = _statusInfo(delivery.status);
    // Mã đơn thật là UUID dài (ví dụ 6d64dc06-68fb-4146-9758-f1f16134ba6f) -
    // hiển thị rút gọn 8 ký tự đầu viết hoa (khớp đúng kiểu shortId đã dùng
    // ở ActiveDeliveryScreen) để không bị tràn dòng, dễ đọc.
    final shortId = delivery.deliveryId.length >= 8
        ? delivery.deliveryId.substring(0, 8).toUpperCase()
        : delivery.deliveryId.toUpperCase();
    // Cùng 1 kiểu chữ tiêu đề mục với "Đi đến điểm lấy hàng" bên
    // ActiveDeliveryScreen - để 2 màn hình nhất quán về phân cấp chữ.
    final headingStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mã đơn', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      Text(
                        '#$shortId',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Trạng thái hiện tại', style: headingStyle),
          const SizedBox(height: 8),
          // Thẻ trạng thái nổi bật hơn (nền mint đậm) - tách riêng khỏi thẻ
          // mã đơn ở trên để shipper thấy ngay đơn đang ở bước nào và cần
          // làm gì tiếp theo, không phải đoán qua mã trạng thái thô.
          _SectionCard(
            color: _statusCardColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusDescription(delivery.status),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Cước phí chuyến này', style: headingStyle),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${money.format(delivery.totalFee)} đ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                if (routeQuote != null) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.route_outlined, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Còn ${routeQuote!.distanceKm.toStringAsFixed(1)} km  •  ~${routeQuote!.durationMin.round()} phút '
                          'từ vị trí của bạn tới điểm của bước hiện tại (ước tính)',
                          style: const TextStyle(color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Địa chỉ giao nhận', style: headingStyle),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddressRow(
                  icon: Icons.storefront_outlined,
                  label: 'Điểm lấy hàng',
                  address: delivery.pickupAddress,
                  onOpenMap: () => _openMap(context, delivery.pickupAddress),
                ),
                const Divider(height: 24),
                _AddressRow(
                  icon: Icons.flag_outlined,
                  label: 'Điểm giao hàng',
                  address: delivery.dropoffAddress,
                  onOpenMap: () => _openMap(context, delivery.dropoffAddress),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Người nhận', style: headingStyle),
          const SizedBox(height: 8),
          _SectionCard(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEFF3F1),
                  child: Icon(Icons.person_outline, color: AppTheme.textDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // Backend hiện chỉ trả receiverPhone, KHÔNG có tên người
                    // nhận - xem TODO trong models/delivery.dart.
                    delivery.receiverPhone ?? 'Chưa có số điện thoại',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (delivery.receiverPhone != null)
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: AppTheme.primary,
                    ),
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () => _callReceiver(context, delivery.receiverPhone!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Lịch sử thời gian', style: headingStyle),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimelineRow(label: 'Nhận đơn', time: delivery.assignedAt),
                _TimelineRow(label: 'Lấy hàng', time: delivery.pickedUpAt),
                _TimelineRow(label: 'Bắt đầu giao', time: delivery.deliveringAt),
                _TimelineRow(label: 'Hoàn tất', time: delivery.completedAt),
                if (delivery.cancelledAt != null)
                  _TimelineRow(label: 'Huỷ đơn', time: delivery.cancelledAt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card nền TRẮNG (mặc định) hoặc màu tuỳ chỉnh qua [color] - đặt màu rõ
/// ràng thay vì để Card tự suy màu nền theo theme (dễ bị lẫn với nền trang
/// mint của OrderDetailScreen), kèm viền mỏng để vẫn phân biệt được với nền
/// khi cùng tông màu (ví dụ card trạng thái mint trên nền cũng mint).
class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _SectionCard({required this.child, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final VoidCallback onOpenMap;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(address, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.map_outlined, color: AppTheme.primary),
          onPressed: onOpenMap,
          tooltip: 'Mở Google Maps',
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime? time;
  const _TimelineRow({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    final done = time != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppTheme.primary : AppTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: done ? AppTheme.textDark : AppTheme.textMuted),
            ),
          ),
          Text(
            done ? DateFormat('dd/MM HH:mm').format(time!) : '--',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
