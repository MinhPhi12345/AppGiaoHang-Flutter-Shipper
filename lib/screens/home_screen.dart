import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isOnline = false; // Trạng thái mặc định chỉ có map, không tìm đơn
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Dịch vụ định vị (GPS) đang bị tắt. Vui lòng bật GPS.';
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Quyền truy cập vị trí bị từ chối.';
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError = 'Quyền truy cập vị trí bị từ chối vĩnh viễn trong cài đặt.';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Không thể lấy vị trí hiện tại: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    // Tạm thời update UI ngay để mượt mà (Optimistic Update)
    setState(() {
      _isOnline = value;
    });

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/me/availability');
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        // Gửi status AVAILABLE hoặc OFFLINE theo chuẩn enum
        body: jsonEncode({'status': value ? 'AVAILABLE' : 'OFFLINE'}),
      );

      if (response.statusCode >= 400) {
        throw Exception('Server returned ${response.statusCode}');
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Đã bật nhận đơn' : 'Đã tắt nhận đơn'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Nếu API lỗi, revert lại trạng thái UI cũ
      if (mounted) {
        setState(() {
          _isOnline = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật trạng thái: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : _locationError.isNotEmpty
                    ? _buildErrorView()
                    : _buildMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _locationError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingLocation = true;
                  _locationError = '';
                });
                _determinePosition();
              },
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E9E6A), // Màu xanh theo thiết kế
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            // child: Image.network(...) nếu có ảnh avatar
            child: Icon(Icons.person, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Nguyễn Văn Hùng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tài xế • ★ 4.9',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text(
                'bật / tắt',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              Switch(
                value: _isOnline,
                onChanged: _toggleAvailability,
                activeColor: Colors.white,
                activeTrackColor: Colors.green.shade300,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _currentPosition!,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              // Sử dụng OpenStreetMap (Raster tiles) là giải pháp phổ biến và ổn định nhất cho flutter_map
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app', // Thay bằng package name thật của bạn
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E9E6A).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E9E6A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Banner trạng thái: Chỉ hiển thị khi đang bật nhận đơn (isOnline == true)
        if (_isOnline)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Đang tìm đơn hàng gần đây...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF1E9E6A),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
