import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import 'app_data.dart';

/// Supabase repository — For shared groups and personal data backup.
/// Personal data (expenses, shopping lists, calendar) lives in local SQLite.
class SupabaseRepository {
  static final SupabaseClient client = Supabase.instance.client;

  // -- User Session --
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // -- Auth Methods (only needed for shared expenses) --
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── Shared Expenses (Cloud-synced via Supabase) ─────────────
  
  /// Une al usuario actual a un grupo compartido mediante su UUID (Deep Link/QR)
  static Future<void> joinSharedGroup(String groupId) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero.');
    
    // Inserción en la tabla puente group_members en Supabase
    await client.from('group_members').insert({
      'group_id': groupId,
      'user_id': user.id,
      'joined_at': DateTime.now().toIso8601String(),
    });
    
    // TODO: (Opcional) Refrescar la lista local AppData.sharedGroups 
    // descargando los datos del grupo recién unido.
  }

  // ── Personal Expenses Sync (Cloud Backup) ─────────────
  
  static Future<void> syncExpense(Expense expense) async {
    final user = currentUser;
    if (user == null) return; // Silent return si no está logueado, se queda offline.

    try {
      await client.from('user_expenses').upsert({
        'id': expense.id,
        'user_id': user.id,
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'category': expense.module,
        'currency': AppData.currency,
        'attached_file_path': expense.attachedFileName,
      });
    } catch (e) {
      // Ignorar fallo de subida, se quedará offline y se podría sincronizar después
      print("Error syncing expense to cloud: $e");
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('user_expenses').delete().eq('id', expenseId).eq('user_id', user.id);
    } catch (e) {
      print("Error deleting expense in cloud: $e");
    }
  }

  static Future<List<Expense>> fetchUserExpenses() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final response = await client.from('user_expenses').select().eq('user_id', user.id);
      return (response as List).map((data) => Expense(
        id: data['id'],
        title: data['title'],
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date']),
        module: data['category'],
        attachedFileName: data['attached_file_path'],
      )).toList();
    } catch (e) {
      print("Error fetching expenses from cloud: $e");
      return [];
    }
  }
}
