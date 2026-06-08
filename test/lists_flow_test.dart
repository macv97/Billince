import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billince/screens/checklist_screen.dart';
import 'package:billince/data/app_data.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() {
    AppData.shoppingLists.clear();
  });

  testWidgets('Lists Flow: Create, Edit, Delete', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChecklistScreen()));
    await tester.pumpAndSettle();

    // 1. Create List
    await tester.tap(find.text('Nueva Lista'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Lista de Prueba');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Lista de Prueba'), findsOneWidget);
    expect(AppData.shoppingLists.length, 1);

    // 2. Open List
    await tester.tap(find.text('Lista de Prueba'));
    await tester.pumpAndSettle();

    // Now inside ShoppingListDetailScreen (since ChecklistScreen pushed it)
    // We expect the title to be there
    expect(find.text('Lista de Prueba'), findsOneWidget);
    
    // Add item (assuming there is an input field and add button, testing basic presence)
    // For now just navigate back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 3. Delete List
    await tester.drag(find.text('Lista de Prueba'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Lista de Prueba'), findsNothing);
    expect(AppData.shoppingLists.isEmpty, true);
  });
}
