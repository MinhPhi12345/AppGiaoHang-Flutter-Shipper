import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/dev_token_holder.dart';
import 'screens/active_delivery_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/offer_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'state/delivery_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TODO: khi SessionProvider thật xong, ApiClient nên lấy token từ đó
        // (SessionProvider.apiClient) thay vì DevTokenHolder tạm thời này.
        ChangeNotifierProvider(
          create: (_) => DeliveryProvider(
            ApiClient(getAccessToken: () => DevTokenHolder.token),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'App Tài Xế',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _DevMenu(),
      ),
    );
  }
}

/// KHUNG TẠM - màn hình liệt kê nhanh từng screen + chỗ dán accessToken test
/// tay (xem README, mục "Lấy token test tạm thời"), không phải luồng điều
/// hướng thật của app. Xoá đi khi đã nối xong đăng nhập thật (SessionProvider).
class _DevMenu extends StatefulWidget {
  const _DevMenu();

  @override
  State<_DevMenu> createState() => _DevMenuState();
}

class _DevMenuState extends State<_DevMenu> {
  final _tokenController = TextEditingController(text: DevTokenHolder.token);
  final _orderIdController = TextEditingController();
  bool _isLoadingOrder = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  void _saveToken() {
    DevTokenHolder.token = _tokenController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu accessToken tạm thời (chỉ trong bộ nhớ).')),
    );
  }

  Future<void> _loadOrderAndOpen() async {
    final orderId = _orderIdController.text.trim();
    if (orderId.isEmpty) return;
    setState(() => _isLoadingOrder = true);
    final error =
        await context.read<DeliveryProvider>().loadActiveDeliveryByOrderId(orderId);
    if (!mounted) return;
    setState(() => _isLoadingOrder = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveDeliveryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <String, WidgetBuilder>{
      'Đăng nhập (login_screen)': (_) => const LoginScreen(),
      'Trang chủ (home_screen)': (_) => const HomeScreen(),
      'Lời mời nhận đơn (offer_screen)': (_) => const OfferScreen(),
      'Đang giao hàng (active_delivery_screen)': (_) => const ActiveDeliveryScreen(),
      'Hồ sơ (profile_screen)': (_) => const ProfileScreen(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách màn hình (dev)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Test tạm - dán accessToken (xem README) rồi nhập orderId để mở '
            'thẳng ActiveDeliveryScreen với dữ liệu thật từ backend:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(labelText: 'accessToken (JWT)'),
            maxLines: 2,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _saveToken, child: const Text('Lưu token')),
          ),
          TextField(
            controller: _orderIdController,
            decoration: const InputDecoration(labelText: 'orderId (GUID)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoadingOrder ? null : _loadOrderAndOpen,
            child: Text(_isLoadingOrder ? 'Đang tải...' : 'Tải chuyến & mở Đang giao hàng'),
          ),
          const Divider(height: 32),
          ...screens.entries.map(
            (entry) => ListTile(
              title: Text(entry.key),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: entry.value),
              ),
            ),
          ),
          ListTile(
            title: const Text('Chi tiết đơn hàng (order_detail_screen)'),
            subtitle: const Text('Cần đã tải một chuyến qua ô orderId ở trên trước'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final delivery = context.read<DeliveryProvider>().activeDelivery;
              if (delivery == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chưa có chuyến nào được tải - nhập orderId ở trên trước.')),
                );
                return;
              }
              final routeQuote = context.read<DeliveryProvider>().routeQuote;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(delivery: delivery, routeQuote: routeQuote),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
