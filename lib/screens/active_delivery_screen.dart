import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../core/external_navigation.dart';
import '../models/delivery.dart';
import '../models/route_quote.dart';
import '../state/delivery_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_map_preview.dart';
import 'order_detail_screen.dart';

/// Màn hình "đang giao hàng" - tập trung vào bước ĐANG làm (địa chỉ của
/// bước hiện tại + trượt để xác nhận). Xem TOÀN BỘ thông tin đơn (cả 2 địa
/// chỉ, cước phí, lịch sử thời gian) thì bấm vào tiêu đề hoặc icon biên nhận
/// nổi trên bản đồ (xem [_openOrderDetail]). Tài xế đổi trạng thái bằng
/// cách TRƯỢT nút ở cuối màn hình (kiểu Grab/ShopeeFood), KHÔNG phải bấm
/// nút thường - tránh bấm nhầm khi đang cầm hàng/lái xe.
///
/// Bản đồ LUÔN phủ kín toàn bộ chiều rộng màn hình (full-bleed, tràn cả lên
/// status bar) - không còn là khung nhỏ bo góc như bản trước. Bấm icon
/// phóng to nổi trên bản đồ (xem [_isMapFocused]) để bản đồ chiếm gần hết
/// màn hình, ẩn bớt phần thông tin chi tiết bên dưới - tiện khi tài xế chỉ
/// cần nhìn nhanh hướng đi mà không cần đọc hết thông tin.
///
/// 3 trạng thái tài xế tự chuyển (xác nhận từ code thật DeliveryWorkflowService.
/// ChangeDriverStageAsync bên backend, không phải tự đặt ra):
///   ASSIGNED -(pickup)-> PICKED_UP -(start)-> DELIVERING -(complete)-> COMPLETED
class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> with WidgetsBindingObserver {
  final _slideKey = GlobalKey<SlideActionState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App vừa quay lại foreground (ví dụ tài xế thoát ra bật định vị/cấp
  /// quyền vị trí trong Cài đặt máy rồi quay lại app) - nếu lần tải vị trí
  /// gần nhất đang bị lỗi thì tự thử tải lại luôn, không bắt tài xế phải tự
  /// bấm "Thử lại" trên bản đồ. Chỉ retry khi ĐANG có lỗi và vẫn còn chuyến
  /// hoạt động, tránh gọi lại API không cần thiết mỗi lần chuyển app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final provider = context.read<DeliveryProvider>();
    if (provider.routeError != null && provider.activeDelivery != null) {
      provider.retryDriverLocation();
    }
  }

  /// true = đang ở chế độ "phóng to bản đồ, ẩn bớt thông tin" (xem doc
  /// comment class). Chỉ là state hiển thị cục bộ của màn hình này, không
  /// ảnh hưởng dữ liệu/DeliveryProvider.
  bool _isMapFocused = false;

  /// Chiều cao khung bản đồ khi KHÔNG phóng to - tính theo TỈ LỆ chiều cao
  /// màn hình (không phải số cố định) để hiển thị hợp lý trên nhiều kích
  /// thước máy khác nhau. Khi phóng to thì dùng Expanded để lấp đầy hết
  /// phần còn lại phía trên panel trượt xác nhận.
  static const double _mapHeightFraction = 0.42;

  // Đúng thứ tự 3 bước tài xế thao tác - KHÔNG tự thêm/bớt, khớp với backend.
  static const _stages = [
    (status: 'ASSIGNED', label: 'Đã nhận đơn', icon: Icons.assignment_turned_in_outlined),
    (status: 'PICKED_UP', label: 'Đã lấy hàng', icon: Icons.inventory_2_outlined),
    (status: 'DELIVERING', label: 'Đang giao', icon: Icons.local_shipping_outlined),
  ];

  Future<void> _handleSlideSubmit(Delivery delivery) async {
    setState(() => _isSubmitting = true);
    final error = await context.read<DeliveryProvider>().advanceStage();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      _slideKey.currentState?.reset();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final stillActive = context.read<DeliveryProvider>().activeDelivery != null;
    if (!stillActive) {
      // Vừa complete xong - DeliveryProvider đã tự set activeDelivery = null.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tất giao hàng!')),
      );
      Navigator.of(context).pop();
      return;
    }
    // Chuyển sang bước tiếp theo - reset slider để tài xế trượt lại từ đầu
    // cho hành động kế tiếp (ví dụ vừa "Đã lấy hàng" xong thì cần trượt tiếp
    // để "Bắt đầu giao").
    _slideKey.currentState?.reset();
  }

  /// Mở Google Maps chỉ đường TỪ VỊ TRÍ HIỆN TẠI của tài xế ĐẾN điểm của
  /// bước đang làm ([targetLatitude]/[targetLongitude] - điểm lấy khi
  /// ASSIGNED, điểm giao khi PICKED_UP/DELIVERING). Luôn truyền rõ vị trí
  /// tài xế (từ DeliveryProvider.driverLatitude/driverLongitude - toạ độ
  /// GPS thật, tải cùng lúc với routeQuote) làm điểm xuất phát, KHÔNG để
  /// Google Maps tự đoán - tránh trường hợp app chỉ đường không đúng ý
  /// (ví dụ từ điểm lấy đến điểm giao thay vì từ vị trí tài xế đến điểm cần
  /// tới hiện tại).
  Future<void> _openMap(
    Delivery delivery, {
    required double targetLatitude,
    required double targetLongitude,
  }) async {
    final driver = context.read<DeliveryProvider>();
    final ok = await ExternalNavigation.openDirections(
      destinationLatitude: targetLatitude,
      destinationLongitude: targetLongitude,
      originLatitude: driver.driverLatitude,
      originLongitude: driver.driverLongitude,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps trên máy này.')),
      );
    }
  }

  Future<void> _callReceiver(String phone) async {
    final ok = await ExternalNavigation.callPhone(phone);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng gọi điện.')),
      );
    }
  }

  void _openOrderDetail(Delivery delivery) {
    final routeQuote = context.read<DeliveryProvider>().routeQuote;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(delivery: delivery, routeQuote: routeQuote),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final delivery = provider.activeDelivery;

    if (delivery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang giao hàng')),
        body: const Center(child: Text('Chưa có chuyến giao hàng nào đang hoạt động.')),
      );
    }

    final isPickupStage = delivery.status == 'ASSIGNED';
    final targetLabel = isPickupStage ? 'Điểm lấy' : 'Điểm giao';
    final targetHeading = isPickupStage ? 'Đi đến điểm lấy hàng' : 'Đi đến điểm giao hàng';
    final targetAddress = isPickupStage ? delivery.pickupAddress : delivery.dropoffAddress;
    final targetLatitude = isPickupStage ? delivery.pickupLatitude : delivery.dropoffLatitude;
    final targetLongitude = isPickupStage ? delivery.pickupLongitude : delivery.dropoffLongitude;
    final currentStageIndex = _stages.indexWhere((s) => s.status == delivery.status);
    final shortId = delivery.deliveryId.length >= 8
        ? delivery.deliveryId.substring(0, 8).toUpperCase()
        : delivery.deliveryId.toUpperCase();

    final miniMap = MiniMapPreview(
      key: ValueKey('${delivery.status}-${delivery.deliveryId}'),
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
      targetLabel: targetLabel,
      driverLatitude: provider.driverLatitude,
      driverLongitude: provider.driverLongitude,
      isLoadingDriverPosition: provider.isLoadingRoute,
      driverPositionError: provider.routeError,
      onRetry: () => context.read<DeliveryProvider>().retryDriverLocation(),
    );

    // Header đơn hàng (nút quay lại, mã đơn/trạng thái, icon chi tiết + hỗ
    // trợ) giờ NỔI TRỰC TIẾP trên bản đồ (chữ trắng có đổ bóng, các nút bo
    // tròn nền trắng để luôn bấm được dù nền bản đồ màu gì) thay vì nằm
    // trong thanh riêng phía trên - để bản đồ phủ được TOÀN BỘ khúc trên
    // màn hình, kể cả phần dưới status bar (xem SafeArea(top: false) bên
    // dưới). Bọc riêng trong SafeArea(bottom: false) để chữ/nút không bị
    // status bar (đồng hồ, pin) che mất.
    final headerOverlay = Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            children: [
              _MapCircleButton(
                icon: Icons.arrow_back,
                tooltip: 'Quay lại',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openOrderDetail(delivery),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đơn #$shortId', style: _MapOverlayText.style(bold: true)),
                        Text(
                          '${delivery.status} • cập nhật ${DateFormat('HH:mm').format(delivery.lastUpdatedAt)}',
                          style: _MapOverlayText.style(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MapCircleButton(
                icon: Icons.receipt_long_outlined,
                tooltip: 'Xem chi tiết đơn',
                onTap: () => _openOrderDetail(delivery),
              ),
              const SizedBox(width: 8),
              _MapCircleButton(
                icon: Icons.help_outline,
                tooltip: 'Hỗ trợ',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('TODO: thông tin hỗ trợ tài xế')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final mapToggleButton = Positioned(
      right: 8,
      bottom: 8,
      child: _MapCircleButton(
        icon: _isMapFocused ? Icons.close_fullscreen : Icons.open_in_full,
        tooltip: _isMapFocused ? 'Thu nhỏ bản đồ' : 'Phóng to bản đồ',
        onTap: () => setState(() => _isMapFocused = !_isMapFocused),
      ),
    );

    // Bản đồ luôn phủ full-bleed (không padding 2 bên, không bo góc) - CHỈ
    // khác nhau ở CHIỀU CAO (SizedBox theo % màn hình khi thu nhỏ, Expanded
    // lấp đầy khi phóng to). Giữ đúng "hình dạng cây widget" giống nhau ở cả
    // 2 nhánh (Stack chứa Positioned.fill(miniMap) + 2 nút nổi) để Flutter
    // KHÔNG huỷ/tạo lại MiniMapPreview (mất icon, phải tải lại) mỗi lần bấm
    // nút phóng to/thu nhỏ.
    final mapArea = Stack(
      children: [
        Positioned.fill(child: miniMap),
        headerOverlay,
        mapToggleButton,
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // top: false để bản đồ được vẽ tràn lên cả vùng status bar (giống
        // app điều hướng thật) - phần header nổi bên trong mapArea tự lo
        // padding an toàn riêng (xem headerOverlay ở trên). SafeArea ở đây
        // vẫn chừa khoảng trống phía DƯỚI (thanh cử chỉ/home indicator) cho
        // panel trượt xác nhận hoặc danh sách chi tiết bên dưới bản đồ.
        top: false,
        child: Column(
          children: [
            if (_isMapFocused)
              Expanded(child: mapArea)
            else
              SizedBox(
                height: MediaQuery.of(context).size.height * _mapHeightFraction,
                child: mapArea,
              ),
            if (_isMapFocused)
              _FocusedActionPanel(
                targetHeading: targetHeading,
                targetAddress: targetAddress,
                slideKey: _slideKey,
                slideLabel: _slideLabel(delivery.status),
                isSubmitting: _isSubmitting,
                onSubmit: () => _handleSlideSubmit(delivery),
              )
            else
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Text(targetHeading, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(targetAddress, style: const TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 12),
                      _RouteEstimateCard(
                        routeQuote: provider.routeQuote,
                        isLoading: provider.isLoadingRoute,
                        error: provider.routeError,
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEFF3F1),
                            child: Icon(Icons.person_outline, color: AppTheme.textDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Người nhận', style: TextStyle(fontWeight: FontWeight.w600)),
                                // Backend hiện chỉ trả receiverPhone, KHÔNG có tên
                                // người nhận - xem TODO trong models/delivery.dart.
                                Text(
                                  delivery.receiverPhone ?? 'Chưa có số điện thoại',
                                  style: const TextStyle(color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (delivery.receiverPhone != null)
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryLight,
                                foregroundColor: AppTheme.primary,
                              ),
                              icon: const Icon(Icons.call_outlined),
                              onPressed: () => _callReceiver(delivery.receiverPhone!),
                            ),
                        ],
                      ),
                      const Divider(height: 32),
                      ..._stages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stage = entry.value;
                        final isDone = currentStageIndex >= 0 && index < currentStageIndex;
                        final isCurrent = index == currentStageIndex;
                        final color = isCurrent
                            ? AppTheme.primary
                            : (isDone ? AppTheme.textDark : AppTheme.textMuted);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(isDone ? Icons.check_circle : stage.icon, color: color, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                stage.label,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => _openMap(
                          delivery,
                          targetLatitude: targetLatitude,
                          targetLongitude: targetLongitude,
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: Text('Mở Google Maps • $targetLabel'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SlideAction(
                        key: _slideKey,
                        text: _slideLabel(delivery.status),
                        textStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                        outerColor: AppTheme.primaryLight,
                        innerColor: AppTheme.primary,
                        sliderButtonIcon: const Icon(Icons.arrow_forward, color: Colors.white),
                        borderRadius: 12,
                        elevation: 0,
                        enabled: !_isSubmitting,
                        onSubmit: () => _handleSlideSubmit(delivery),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _slideLabel(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 'Trượt để xác nhận đã lấy hàng';
      case 'PICKED_UP':
        return 'Trượt để bắt đầu giao';
      case 'DELIVERING':
        return 'Trượt để hoàn tất giao hàng';
      default:
        return 'Không có hành động tiếp theo';
    }
  }
}

/// Nút tròn nền trắng nổi trên bản đồ (icon quay lại, chi tiết đơn, hỗ trợ,
/// phóng to/thu nhỏ) - dùng chung 1 kiểu để luôn bấm được và nhìn rõ dù nền
/// bản đồ phía dưới đang là màu gì (đường, công viên, sông...).
class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  const _MapCircleButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppTheme.textDark),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Kiểu chữ dùng cho phần header nổi trực tiếp trên bản đồ - luôn màu
/// trắng + đổ bóng nhẹ để đọc được trên mọi màu nền của bản đồ bên dưới.
class _MapOverlayText {
  static TextStyle style({bool bold = false, double fontSize = 15}) => TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1))],
      );
}

/// Panel gọn hiện khi [_ActiveDeliveryScreenState._isMapFocused] = true -
/// chỉ giữ lại đúng phần cần thiết (tiêu đề bước hiện tại + nút trượt xác
/// nhận), ẩn hết phần chi tiết (thẻ ước tính, người nhận, lịch sử trạng
/// thái, nút Google Maps) để nhường chỗ cho bản đồ phóng to phía trên.
class _FocusedActionPanel extends StatelessWidget {
  final String targetHeading;
  final String targetAddress;
  final GlobalKey<SlideActionState> slideKey;
  final String slideLabel;
  final bool isSubmitting;
  final Future<dynamic>? Function() onSubmit;

  const _FocusedActionPanel({
    required this.targetHeading,
    required this.targetAddress,
    required this.slideKey,
    required this.slideLabel,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(targetHeading, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            targetAddress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SlideAction(
            key: slideKey,
            text: slideLabel,
            textStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
            outerColor: AppTheme.primaryLight,
            innerColor: AppTheme.primary,
            sliderButtonIcon: const Icon(Icons.arrow_forward, color: Colors.white),
            borderRadius: 12,
            elevation: 0,
            enabled: !isSubmitting,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

/// Thẻ nhỏ hiển thị khoảng cách + thời gian ước tính TỪ VỊ TRÍ GPS HIỆN TẠI
/// của tài xế tới điểm của bước đang làm (điểm lấy hoặc điểm giao, tuỳ
/// [Delivery.status]), lấy từ MapService qua [DeliveryProvider.routeQuote]
/// (xem [DeliveryProvider._loadRouteQuote]). Đây CHỈ là số liệu ước lượng
/// đường thẳng (Haversine, xem doc comment RouteQuote), KHÔNG phải khoảng
/// cách đi thực theo đường bộ. Bản đồ xem trước thật (vị trí tài xế + điểm
/// đích) hiển thị riêng ở [MiniMapPreview], phía trên thẻ này. Nếu tài xế
/// không cấp quyền vị trí, thẻ hiện thông báo lỗi thay vì số liệu sai.
class _RouteEstimateCard extends StatelessWidget {
  final RouteQuote? routeQuote;
  final bool isLoading;
  final String? error;

  const _RouteEstimateCard({
    required this.routeQuote,
    required this.isLoading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _RouteEstimateShell(
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
            SizedBox(width: 8),
            Text('Đang tính khoảng cách...', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    if (routeQuote == null) {
      return _RouteEstimateShell(
        child: Text(
          error ?? 'Chưa có thông tin khoảng cách/thời gian ước tính.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }
    final quote = routeQuote!;
    return _RouteEstimateShell(
      child: Row(
        children: [
          const Icon(Icons.route_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            'Còn ${quote.distanceKm.toStringAsFixed(1)} km  •  ~${quote.durationMin.round()} phút',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const Spacer(),
          const Text('từ vị trí của bạn', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RouteEstimateShell extends StatelessWidget {
  final Widget child;
  const _RouteEstimateShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
