import 'package:flutter_test/flutter_test.dart';
import 'package:billince/models/expense.dart';
import 'package:billince/models/checklist_item.dart';

void main() {
  group('Billince App Core Logic Tests', () {
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

    test('Checklist item logic', () {
      final item = ChecklistItem(
        id: 'chk-01',
        title: 'Leche',
        isDone: false,
        price: 1.20,
      );

      expect(item.isDone, false);
      expect(item.price, 1.20);
      
      item.isDone = true;
      expect(item.isDone, true);
    });
  });
}
