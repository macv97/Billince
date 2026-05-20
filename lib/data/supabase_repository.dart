import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/checklist_item.dart';
import '../models/shared_expense.dart';
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

  // ── Personal Shopping Lists Sync (Cloud Backup) ─────────────

  static Future<void> syncShoppingList(ShoppingList list) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await client.from('user_shopping_lists').upsert({
        'id': list.id,
        'user_id': user.id,
        'title': list.title,
        'date_created': list.dateCreated.toIso8601String(),
      });

      // Sync items
      for (var item in list.items) {
        await client.from('user_checklist_items').upsert({
          'id': item.id,
          'list_id': list.id,
          'title': item.title,
          'is_done': item.isDone,
          'price': item.price,
        });
      }
    } catch (e) {
      print("Error syncing shopping list: $e");
    }
  }

  static Future<void> deleteShoppingList(String listId) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('user_shopping_lists').delete().eq('id', listId).eq('user_id', user.id);
    } catch (e) {
      print("Error deleting shopping list: $e");
    }
  }

  static Future<List<ShoppingList>> fetchUserShoppingLists() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final listResponse = await client.from('user_shopping_lists').select().eq('user_id', user.id);
      final List<ShoppingList> result = [];
      
      for (var listData in listResponse as List) {
        final listId = listData['id'];
        final itemsResponse = await client.from('user_checklist_items').select().eq('list_id', listId);
        
        final items = (itemsResponse as List).map((i) => ChecklistItem(
          id: i['id'],
          title: i['title'],
          isDone: i['is_done'],
          price: (i['price'] as num).toDouble(),
        )).toList();

        result.add(ShoppingList(
          id: listId,
          title: listData['title'],
          dateCreated: DateTime.parse(listData['date_created']),
          items: items,
        ));
      }
      return result;
    } catch (e) {
      print("Error fetching shopping lists: $e");
      return [];
    }
  }

  // ── Shared Expenses Sync ─────────────

  static Future<void> syncSharedExpense(SharedExpense expense, String groupId) async {
    // Unlike personal, shared events are uploaded whether you are owner or member
    try {
      await client.from('shared_expenses').upsert({
        'id': expense.id,
        'group_id': groupId,
        'payer': expense.payer,
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'participants': expense.participants.join(','),
      });
    } catch (e) {
      print("Error syncing shared expense: $e");
    }
  }
}
