import 'package:flutter/material.dart';
import 'core/session_store.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Bắt buộc gọi dòng này khi dùng async trong main
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra trạng thái đăng nhập
  final token = await SessionStore.getAccessToken();
  final bool isLoggedIn = token != null && token.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Tài Xế',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Nếu đã có token thì vào thẳng Home, ngược lại thì bắt đăng nhập
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
