import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billince/screens/expenses_screen.dart';
import 'package:billince/data/app_data.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() {
    AppData.expenses.clear();
  });

  testWidgets('Gastos Flow: Add, Edit, Delete', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExpensesScreen()));
    await tester.pumpAndSettle();

    // 1. Add Manual Expense
    await tester.tap(find.text('AÑADIR'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Añadir Manualmente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Concepto o Comercio'), 'Mercadona Test');
    await tester.enterText(find.widgetWithText(TextFormField, 'Importe Total'), '15.50');
    
    await tester.tap(find.text('Guardar Gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Mercadona Test'), findsOneWidget);
    expect(AppData.expenses.length, 1);
    
    // 2. Edit Expense
    await tester.tap(find.text('Mercadona Test'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Importe Total'), '20.00');
    await tester.tap(find.text('Actualizar Gasto'));
    await tester.pumpAndSettle();

    expect(AppData.expenses.first.amount, 20.0);

    // 3. Delete Expense
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    
    expect(find.text('Mercadona Test'), findsNothing);
    expect(AppData.expenses.isEmpty, true);
  });
}
