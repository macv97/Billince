import 'package:uuid/uuid.dart';
import '../data/app_data.dart';
import '../data/local_database.dart';

class AppActivityLogger {
  static void logActivity({
    required String title,
    String? description,
    required String category, // e.g., 'finance', 'work', 'personal', 'history'
  }) {
    final event = CalendarEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateTime: DateTime.now(),
      category: category,
      isAllDay: true,
      isDone: true,
    );
    
    AppData.calendarEvents.add(event);
    LocalDatabase.insertCalendarEvent(event);
  }

  static void logExpenseAdded(String title, double amount) {
    logActivity(
      title: 'Añadido gasto: $title',
      description: 'Importe: ${AppData.currency}${amount.toStringAsFixed(2)}',
      category: 'finance',
    );
  }

  static void logJoinedEvent(String title) {
    logActivity(
      title: 'Unido a evento: $title',
      category: 'history',
    );
  }

  static void logCreatedEvent(String title) {
    logActivity(
      title: 'Creado evento: $title',
      category: 'history',
    );
  }

  static void logJoinedChecklist(String title) {
    logActivity(
      title: 'Unido a lista: $title',
      category: 'history',
    );
  }

  static void logCreatedChecklist(String title) {
    logActivity(
      title: 'Creada lista: $title',
      category: 'history',
    );
  }
}
