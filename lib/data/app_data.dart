import '../models/expense.dart';
import '../models/shared_group.dart';

class AppData {
  static String currency = '\$'; // Default currency

  static final List<Expense> expenses = [];
  static final List<String> modules = ['General', 'Compras', 'Transporte', 'Hogar', 'Ocio', 'Viaje'];

  // Compartir gastos (Eventos/Grupos estilo Tricount)
  static final List<SharedExpenseGroup> sharedGroups = [
    SharedExpenseGroup(
      id: 'demo1',
      title: 'Viaje a Asturias',
      members: ['Tú', 'Ana', 'Carlos'],
      expenses: [],
      files: [],
      currency: '€',
    )
  ];
}
