// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:billince/models/expense.dart';

void main() {
  test('Expense model initialization test', () {
    final expense = Expense(
      id: 'test-123',
      title: 'Mercadona',
      amount: 15.75,
      date: DateTime(2026, 5, 6),
      module: 'Alimentación',
    );

    expect(expense.id, 'test-123');
    expect(expense.title, 'Mercadona');
    expect(expense.amount, 15.75);
    expect(expense.module, 'Alimentación');
  });
}
