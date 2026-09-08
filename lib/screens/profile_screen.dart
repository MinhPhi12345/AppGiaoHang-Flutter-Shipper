import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/session_store.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingLogout = false;
  
  // Biến lưu trữ dữ liệu người dùng
  String _userName = 'Đang tải...';
  String _rating = 'Tài xế • ★ 4.9'; // Tạm thời fix cứng rating

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final data = await ApiClient.get('/api/identity/me');
      if (mounted) {
        setState(() {
          // Lấy trường username hoặc name từ JSON
          _userName = data['username'] ?? data['name'] ?? data['fullName'] ?? 'Tài xế ẩn danh';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = e is ApiException ? e.message : 'Không có kết nối';
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoadingLogout = true;
    });

    try {
      // API Logout yêu cầu truyền refreshToken
      final refreshToken = await SessionStore.getRefreshToken() ?? '';
      
      await ApiClient.post(
        '/api/identity/logout',
        body: {'refreshToken': refreshToken},
        requiresAuth: true,
      );

      // Xóa toàn bộ token dưới local
      await SessionStore.clear();

      if (!mounted) return;

      // Đăng xuất thành công, chuyển sang màn hình Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : 'Lỗi kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLogout = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Nửa trên màu xanh nhạt
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              color: const Color(0xFFE8F6F3), // Xanh mint nhạt theo thiết kế
            ),
          ),
          
          // Nội dung chính
          Column(
            children: [
              const SizedBox(height: 130), // Căn avatar đè lên đường viền màu xanh
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 72,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _rating,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E9E6A), // Màu xanh lá cây
                ),
              ),
            ],
          ),

          // Nút đăng xuất ở dưới cùng
          Positioned(
            bottom: 40,
            left: 48,
            right: 48,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _isLoadingLogout ? null : _handleLogout,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoadingLogout
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Text(
                        'Đăng Xuất',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
