import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billince/screens/summary_screen.dart';
import 'package:billince/data/app_data.dart';
import 'package:billince/models/expense.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() {
    AppData.expenses.clear();
  });

  testWidgets('Stats / Summary Flow', (WidgetTester tester) async {
    // Add dummy data
    AppData.expenses.add(Expense(
      id: 'e1', title: 'Test 1', amount: 10.0, date: DateTime.now(), module: 'General'
    ));
    AppData.expenses.add(Expense(
      id: 'e2', title: 'Test 2', amount: 20.0, date: DateTime.now(), module: 'Ocio'
    ));

    await tester.pumpWidget(const MaterialApp(home: SummaryScreen()));
    await tester.pumpAndSettle();

    // Verify totals
    expect(find.textContaining('30.0'), findsWidgets); // Total amount
    expect(find.text('2'), findsWidgets); // 2 transactions
    expect(find.text('Gastos'), findsWidgets);
  });
}

