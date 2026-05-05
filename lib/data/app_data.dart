import '../models/expense.dart';
import '../models/shared_group.dart';
import '../models/checklist_item.dart';

class AppData {
  static String currency = '€'; // Default currency EUR

  static final List<Expense> expenses = [];
  static final List<String> modules = ['General', 'Compras', 'Transporte', 'Hogar', 'Ocio', 'Viaje'];

  // Shared expense groups
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

  // Shopping lists
  static final List<ShoppingList> shoppingLists = [];

  // Calendar events
  static final List<CalendarEvent> calendarEvents = [];
}

/// Model for calendar events
class CalendarEvent {
  final String id;
  String title;
  String? description;
  DateTime dateTime;
  DateTime? endDateTime;
  String category; // 'personal', 'work', 'finance', 'health', 'other'
  bool isAllDay;
  bool isDone;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.endDateTime,
    this.category = 'personal',
    this.isAllDay = false,
    this.isDone = false,
  });
}
