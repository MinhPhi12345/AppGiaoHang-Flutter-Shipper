import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';

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

  String _driverName = 'Đang tải...';
  String _driverRating = 'Tài xế • ★ 4.9';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _determinePosition();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiClient.get('/api/identity/me');
      if (mounted) {
        setState(() {
          _driverName = data['username'] ?? data['name'] ?? data['fullName'] ?? 'Tài xế';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _driverName = 'Lỗi kết nối';
        });
      }
    }
  }

  Future<void> _updateLocationToServer(Position position) async {
    try {
      await ApiClient.put(
        '/api/driver/me/location',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracyM': position.accuracy,
          'recordedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      print('Location updated to server successfully.');
    } catch (e) {
      print('Failed to update location to server: $e');
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

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
        // Bắn tọa độ lên Server
        _updateLocationToServer(position);
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
      await ApiClient.patch(
        '/api/driver/me/availability',
        body: {'availabilityStatus': value ? 'AVAILABLE' : 'OFFLINE'},
      );

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
        String errorMessage = e is ApiException ? e.message : 'Lỗi hệ thống';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật trạng thái: $errorMessage'),
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
            child: Icon(Icons.person, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _driverRating,
                  style: const TextStyle(
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
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
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
