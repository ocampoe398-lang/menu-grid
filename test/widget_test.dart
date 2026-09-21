import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_qr/app.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MenuQRApp()));

    // Verify that it builds correctly without throwing
    expect(find.byType(MenuQRApp), findsOneWidget);
  });
}
