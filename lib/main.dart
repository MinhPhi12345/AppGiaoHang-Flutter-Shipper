import 'package:flutter/material.dart';

import 'screens/active_delivery_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/offer_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Tài Xế',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // TODO: khi có SessionProvider thật, thay _DevMenu bằng luồng đăng nhập
      // thật (ví dụ bọc MultiProvider ở đây rồi home: AuthGate()).
      home: const _DevMenu(),
    );
  }
}

/// KHUNG TẠM - màn hình liệt kê nhanh từng screen để mở lên xem/code riêng lẻ,
/// không phải luồng điều hướng thật của app. Xoá đi khi đã nối xong đăng nhập.
class _DevMenu extends StatelessWidget {
  const _DevMenu();

  @override
  Widget build(BuildContext context) {
    final screens = <String, WidgetBuilder>{
      'Đăng nhập (login_screen)': (_) => const LoginScreen(),
      'Trang chủ (home_screen)': (_) => const HomeScreen(),
      'Lời mời nhận đơn (offer_screen)': (_) => const OfferScreen(),
      'Đang giao hàng (active_delivery_screen)': (_) => const ActiveDeliveryScreen(),
      'Chi tiết đơn hàng (order_detail_screen)': (_) => const OrderDetailScreen(),
      'Hồ sơ (profile_screen)': (_) => const ProfileScreen(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách màn hình (dev)')),
      body: ListView(
        children: screens.entries
            .map(
              (entry) => ListTile(
                title: Text(entry.key),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: entry.value),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
