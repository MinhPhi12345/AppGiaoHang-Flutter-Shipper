import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../theme/app_theme.dart';

/// Bản đồ xem trước (KHÔNG chỉ đường từng bước) hiển thị vị trí GPS hiện tại
/// của tài xế (icon xe máy màu xanh dương) và điểm đích của bước đang làm -
/// điểm lấy hoặc điểm giao, tuỳ trạng thái đơn (icon ghim vị trí màu xanh
/// lá, xem [targetLabel]).
///
/// Widget này KHÔNG tự xin định vị - toạ độ tài xế được truyền vào từ
/// [DeliveryProvider.driverLatitude]/[driverLongitude] (tải cùng lúc với
/// routeQuote, xem ActiveDeliveryScreen), để tránh xin quyền vị trí 2 lần
/// (1 lần cho số liệu ước tính, 1 lần cho bản đồ) và đảm bảo bản đồ luôn
/// khớp với số liệu khoảng cách/thời gian hiển thị bên dưới.
///
/// Dùng maplibre_gl (vector tile, mã nguồn mở) + OpenFreeMap
/// (https://openfreemap.org) làm nguồn bản đồ - HOÀN TOÀN MIỄN PHÍ, không
/// cần API key/thẻ tín dụng, không giới hạn request. Widget này chỉ để tài
/// xế "nhìn nhanh" hướng cần đi trước khi bấm nút "Mở Google Maps" để chỉ
/// đường thật từng bước (xem ActiveDeliveryScreen._openMap - hàm đó tự
/// truyền toạ độ tài xế làm điểm xuất phát rõ ràng cho Google Maps, KHÔNG
/// phải chỉ đường từ điểm lấy đến điểm giao) - bản đồ ở đây KHÔNG thay thế
/// app chỉ đường.
///
/// LƯU Ý QUAN TRỌNG: maplibre_gl chỉ hỗ trợ Android/iOS/Web, KHÔNG hỗ trợ
/// Windows/macOS/Linux desktop. Nếu chạy `flutter run -d windows` sẽ lỗi
/// build - test bằng `flutter run -d chrome` hoặc thiết bị/máy ảo Android.
class MiniMapPreview extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final String targetLabel;

  /// Vị trí GPS hiện tại của tài xế - null khi chưa tải xong/không lấy được
  /// (xem [isLoadingDriverPosition] và [driverPositionError] để hiển thị
  /// đúng trạng thái, không âm thầm vẽ sai).
  final double? driverLatitude;
  final double? driverLongitude;
  final bool isLoadingDriverPosition;
  final String? driverPositionError;

  /// Gọi lại khi tài xế bấm nút "Thử lại" ở trạng thái lỗi (ví dụ vừa bật
  /// định vị xong) - null thì không hiện nút (widget dùng ở chỗ khác không
  /// có DeliveryProvider để retry thì có thể bỏ qua).
  final VoidCallback? onRetry;

  const MiniMapPreview({
    super.key,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.targetLabel,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.isLoadingDriverPosition,
    this.driverPositionError,
    this.onRetry,
  });

  @override
  State<MiniMapPreview> createState() => _MiniMapPreviewState();
}

class _MiniMapPreviewState extends State<MiniMapPreview> {
  // Style "bright" của OpenFreeMap - phong cách màu sắc kiểu OpenStreetMap
  // cổ điển (đường màu vàng/cam, công viên xanh lá, sông/hồ xanh dương).
  // Muốn đổi kiểu khác thì chỉ cần sửa tên style ở cuối URL - các lựa chọn
  // khác của OpenFreeMap: liberty, positron, dark, fiord, 3d.
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/bright';

  static const _driverIconName = 'mini-map-driver-icon';
  static const _targetIconName = 'mini-map-target-icon';

  MapLibreMapController? _controller;
  bool _iconsRegistered = false;

  @override
  void didUpdateWidget(covariant MiniMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Vị trí tài xế đổi (vừa tải xong GPS, hoặc tải lại sau khi đổi bước) -
    // hoặc điểm đích đổi (chuyển từ điểm lấy sang điểm giao) - đều cần vẽ
    // lại icon + zoom lại camera.
    final targetChanged = oldWidget.targetLatitude != widget.targetLatitude ||
        oldWidget.targetLongitude != widget.targetLongitude;
    final driverChanged = oldWidget.driverLatitude != widget.driverLatitude ||
        oldWidget.driverLongitude != widget.driverLongitude;
    if (targetChanged || driverChanged) {
      _redrawMarkers();
    }
  }

  Future<void> _registerIconsIfNeeded() async {
    if (_iconsRegistered) return;
    final controller = _controller;
    if (controller == null) return;
    final driverIcon = await _rasterizeIcon(
      Icons.two_wheeler,
      backgroundColor: const Color(0xFF2F80ED),
    );
    final targetIcon = await _rasterizeIcon(
      Icons.location_on,
      backgroundColor: const Color(0xFF27AE60),
    );
    await controller.addImage(_driverIconName, driverIcon);
    await controller.addImage(_targetIconName, targetIcon);
    _iconsRegistered = true;
  }

  /// Vẽ 1 icon Material (ví dụ Icons.two_wheeler) thành ảnh PNG nền tròn có
  /// màu, để dùng làm marker trên bản đồ qua controller.addImage +
  /// addSymbol - maplibre_gl cần ảnh bitmap thật, không nhận IconData/Widget
  /// trực tiếp như cách vẽ icon bình thường trong Flutter.
  Future<Uint8List> _rasterizeIcon(
    IconData icon, {
    required Color backgroundColor,
    double size = 96,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(center, size / 2, Paint()..color = backgroundColor);
    canvas.drawCircle(
      center,
      size / 2 - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.55,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _onStyleLoaded() async {
    await _registerIconsIfNeeded();
    await _redrawMarkers();
  }

  Future<void> _redrawMarkers() async {
    final controller = _controller;
    final driverLat = widget.driverLatitude;
    final driverLng = widget.driverLongitude;
    if (controller == null || !_iconsRegistered || driverLat == null || driverLng == null) {
      return;
    }

    await controller.clearSymbols();
    await controller.addSymbol(
      SymbolOptions(
        geometry: LatLng(driverLat, driverLng),
        iconImage: _driverIconName,
        iconSize: 0.6,
      ),
    );
    await controller.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget.targetLatitude, widget.targetLongitude),
        iconImage: _targetIconName,
        iconSize: 0.6,
      ),
    );

    final south = driverLat < widget.targetLatitude ? driverLat : widget.targetLatitude;
    final north = driverLat > widget.targetLatitude ? driverLat : widget.targetLatitude;
    final west = driverLng < widget.targetLongitude ? driverLng : widget.targetLongitude;
    final east = driverLng > widget.targetLongitude ? driverLng : widget.targetLongitude;

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        left: 40,
        top: 40,
        right: 40,
        bottom: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingDriverPosition && widget.driverLatitude == null) {
      return const _MapShell(
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
        ),
      );
    }

    if (widget.driverLatitude == null || widget.driverLongitude == null) {
      return _MapShell(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined, color: AppTheme.textMuted),
                const SizedBox(height: 8),
                Text(
                  widget.driverPositionError ??
                      'Không lấy được vị trí của bạn để xem bản đồ trước.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return _MapShell(
      child: MapLibreMap(
        styleString: _styleUrl,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.targetLatitude, widget.targetLongitude),
          zoom: 13,
        ),
        onMapCreated: (controller) => _controller = controller,
        onStyleLoadedCallback: _onStyleLoaded,
        myLocationEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        // maplibre_gl KHÔNG có cờ để tắt hẳn icon attribution (đây là ghi
        // công bắt buộc cho OpenFreeMap/OpenStreetMap khi dùng tile miễn
        // phí của họ, chỉ đổi được VỊ TRÍ/màu qua attributionButtonPosition/
        // attributionButtonColor). Đặt xuống bottomLeft (mặc định trước là
        // bottomRight) để KHÔNG còn đè lên nút phóng to/thu nhỏ bản đồ của
        // ActiveDeliveryScreen (cũng đặt ở bottomRight) - đó là lý do icon
        // bị "vướng" trước đây.
        attributionButtonPosition: AttributionButtonPosition.bottomLeft,
      ),
    );
  }
}

/// Khung nền quanh bản đồ - KHÔNG bo góc vì [ActiveDeliveryScreen] giờ
/// luôn hiển thị bản đồ full-bleed (phủ kín cả chiều rộng màn hình, tràn
/// lên status bar), không còn kiểu "card" bo góc như bản trước. height:
/// 160 chỉ là kích thước mặc định khi KHÔNG bị ép buộc từ ngoài -
/// [ActiveDeliveryScreen] luôn bọc widget này trong Positioned.fill bên
/// trong 1 Stack có kích thước rõ ràng (SizedBox theo % chiều cao màn hình
/// lúc thu nhỏ, Expanded lấp đầy lúc phóng to), nên trên thực tế khung này
/// luôn giãn khớp đúng không gian được cấp, height: 160 không có tác dụng
/// trong trường hợp đó.
class _MapShell extends StatelessWidget {
  final Widget child;
  const _MapShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppTheme.primaryLight,
      child: child,
    );
  }
}
