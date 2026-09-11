// Test khởi động cơ bản: chỉ kiểm tra app dựng lên không bị crash.
// Test khởi động cơ bản: chỉ kiểm tra app dựng lên không bị crash.
// Khi có màn hình đăng nhập thật, nên viết thêm test riêng cho từng widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App khởi động không lỗi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
