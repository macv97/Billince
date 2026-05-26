import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:billince/screens/app_lock_screen.dart';

void main() {
  testWidgets('AppLockScreen displays lock icon and text', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLockScreen()));

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('Billince Bloqueado'), findsOneWidget);
    expect(find.text('Desbloquear'), findsOneWidget);
  });
}
