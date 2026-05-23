import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/checklist_item.dart';
import '../models/shared_expense.dart';
import '../models/shared_group.dart';
import '../models/shared_checklist.dart';
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
    return await client.auth.signUp(
      email: email, 
      password: password,
      emailRedirectTo: 'https://billince.app',
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
    AppData.expenses.clear();
    AppData.shoppingLists.clear();
    AppData.sharedGroups.clear();
    AppData.calendarEvents.clear();
    // No borramos SQLite local aquí para que el modo invitado siga funcionando offline, 
    // pero AppData sí se limpia para que la sesión arranque fresca.
  }

  // ── Shared Expenses (Cloud-synced via Supabase) ─────────────
  
  static Future<void> joinSharedGroup(String groupId) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero.');
    
    try {
      final groupCheck = await client.from('shared_groups').select().eq('id', groupId).maybeSingle();
      if (groupCheck == null) {
        throw Exception('No se encontró el grupo. Verifica que el enlace sea correcto y que el creador haya iniciado sesión al crearlo.');
      }

      // Obtener todos los integrantes
      final membersResponse = await client.from('group_members').select('guest_name, user_id').eq('group_id', groupId);
      List<String> members = [];
      String? myMemberName;
      
      for (var mRow in membersResponse as List) {
        final mName = mRow['guest_name'] as String?;
        if (mName != null) {
          members.add(mName);
          if (mRow['user_id'] == user.id) {
            myMemberName = mName; // El usuario ya estaba en el grupo
          }
        }
      }
      
      // Add to AppData if not present
      if (!AppData.sharedGroups.any((g) => g.id == groupId)) {
        final g = SharedExpenseGroup(
          id: groupId,
          title: groupCheck['name'] ?? 'Grupo',
          members: members.isEmpty ? ['Tú'] : members,
          expenses: [],
          files: [],
          currency: groupCheck['currency'] ?? '€',
          myMemberName: myMemberName,
        );
        AppData.sharedGroups.add(g);
      }
    } on PostgrestException catch (e) {
      throw Exception('Error de conexión con la nube: ${e.message}');
    }
  }

  static Future<void> linkUserToMember(String groupId, String memberName) async {
    final user = currentUser;
    if (user == null) return;
    try {
      // Liberar si ya estaba vinculado a otro
      await client.from('group_members').update({'user_id': null}).eq('group_id', groupId).eq('user_id', user.id);
      // Vincular al nuevo
      await client.from('group_members').update({'user_id': user.id}).eq('group_id', groupId).eq('guest_name', memberName);
    } catch (e) {
      print("Error linking user to member: $e");
    }
  }

  static Future<void> leaveSharedGroup(String groupId) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('group_members').delete().eq('group_id', groupId).eq('user_id', user.id);
    } catch (e) {
      print("Error leaving shared group: $e");
    }
  }

  static Future<void> createSharedGroup(SharedExpenseGroup group) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('shared_groups').insert({
        'id': group.id,
        'name': group.title,
        'created_by': user.id,
        'currency': group.currency,
      });
      
      for (var memberName in group.members) {
        final isCreator = memberName == (group.myMemberName ?? 'Tú');
        await client.from('group_members').insert({
          'group_id': group.id,
          'user_id': isCreator ? user.id : null,
          'guest_name': memberName,
        });
      }
    } on PostgrestException catch (e) {
      print("Error creating shared group (Supabase): ${e.message}");
      rethrow;
    } catch (e) {
      print("Error creating shared group: $e");
    }
  }

  static Future<void> updateSharedGroupTitle(String groupId, String newTitle) async {
    try {
      await client.from('shared_groups').update({'name': newTitle}).eq('id', groupId);
    } catch (e) {
      print("Error updating group title: $e");
    }
  }

  static Future<void> updateSharedGroupCurrency(String groupId, String newCurrency) async {
    try {
      await client.from('shared_groups').update({'currency': newCurrency}).eq('id', groupId);
    } catch (e) {
      print("Error updating group currency: $e");
    }
  }

  static Future<List<SharedExpenseGroup>> fetchUserGroups() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final response = await client.from('group_members')
          .select('group_id, shared_groups(name, currency)')
          .eq('user_id', user.id);
      
      List<SharedExpenseGroup> groups = [];
      for (var row in response as List) {
        final groupId = row['group_id'];
        final groupData = row['shared_groups'];
        
        if (groupData != null) {
          // Obtener miembros del grupo
          final membersResponse = await client.from('group_members').select('guest_name, user_id').eq('group_id', groupId);
          List<String> members = [];
          String? myMemberName;
          
          for (var mRow in membersResponse as List) {
            final mName = mRow['guest_name'] as String?;
            if (mName != null) {
              members.add(mName);
              if (mRow['user_id'] == user.id) {
                myMemberName = mName;
              }
            }
          }
          
          if (members.isEmpty) members.add('Tú');
          if (myMemberName == null && members.contains('Tú')) myMemberName = 'Tú';

          groups.add(SharedExpenseGroup(
            id: groupId,
            title: groupData['name'] ?? 'Grupo',
            members: members,
            expenses: [],
            files: [],
            currency: groupData['currency'] ?? '€',
            myMemberName: myMemberName,
          ));
        }
      }
      return groups;
    } catch (e) {
      print("Error fetching user groups: $e");
      return [];
    }
  }

  static Future<List<SharedExpense>> fetchSharedExpenses(String groupId) async {
    try {
      final response = await client.from('shared_expenses').select().eq('group_id', groupId).order('date', ascending: false);
      return (response as List).map((data) => SharedExpense(
        id: data['id'],
        title: data['title'],
        amount: (data['amount'] as num).toDouble(),
        payer: data['payer'],
        participants: (data['participants'] as String).split(',').where((e) => e.isNotEmpty).toList(),
        date: DateTime.parse(data['date']),
      )).toList();
    } catch (e) {
      print("Error fetching shared expenses: $e");
      return [];
    }
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

  // ── Shared Checklists Sync ─────────────

  static Future<void> createSharedChecklist(SharedChecklist list) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('shared_checklists').insert({
        'id': list.id,
        'name': list.name,
        'created_by': user.id,
      });
      
      for (var memberName in list.members) {
        final isCreator = memberName == (list.myMemberName ?? 'Tú');
        await client.from('shared_checklist_members').insert({
          'list_id': list.id,
          'user_id': isCreator ? user.id : null,
          'guest_name': memberName,
        });
      }
    } catch (e) {
      print("Error creating shared checklist: $e");
      rethrow;
    }
  }

  static Future<void> joinSharedChecklist(String listId) async {
    final user = currentUser;
    if (user == null) throw Exception('Debes iniciar sesión primero.');
    
    try {
      final listCheck = await client.from('shared_checklists').select().eq('id', listId).maybeSingle();
      if (listCheck == null) throw Exception('No se encontró la lista compartida.');

      final membersResponse = await client.from('shared_checklist_members').select('guest_name, user_id').eq('list_id', listId);
      List<String> members = [];
      String? myMemberName;
      
      for (var mRow in membersResponse as List) {
        final mName = mRow['guest_name'] as String?;
        if (mName != null) {
          members.add(mName);
          if (mRow['user_id'] == user.id) {
            myMemberName = mName;
          }
        }
      }

      if (!AppData.sharedChecklists.any((l) => l.id == listId)) {
        final g = SharedChecklist(
          id: listId,
          name: listCheck['name'] ?? 'Lista de compra',
          members: members.isEmpty ? ['Tú'] : members,
          items: [],
          logs: [],
          myMemberName: myMemberName,
        );
        AppData.sharedChecklists.add(g);
      }
    } catch (e) {
      throw Exception('Error de conexión con la nube: $e');
    }
  }

  static Future<void> linkUserToChecklistMember(String listId, String memberName) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('shared_checklist_members').update({'user_id': null}).eq('list_id', listId).eq('user_id', user.id);
      await client.from('shared_checklist_members').update({'user_id': user.id}).eq('list_id', listId).eq('guest_name', memberName);
    } catch (e) {
      print("Error linking user to checklist member: $e");
    }
  }

  static Future<void> removeUserFromChecklist(String listId) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('shared_checklist_members').delete().eq('list_id', listId).eq('user_id', user.id);
    } catch (e) {
      print("Error removing user from checklist: $e");
    }
  }

  static Future<void> updateSharedChecklistTitle(String listId, String newTitle) async {
    try {
      await client.from('shared_checklists').update({'name': newTitle}).eq('id', listId);
    } catch (e) {
      print("Error updating checklist title: $e");
    }
  }

  static Future<void> addSharedChecklistMember(String listId, String memberName) async {
    try {
      await client.from('shared_checklist_members').insert({
        'list_id': listId,
        'guest_name': memberName,
        'user_id': null,
      });
    } catch (e) {
      print("Error adding checklist member: $e");
    }
  }

  static Future<void> removeSharedChecklistMemberByGuestName(String listId, String memberName) async {
    try {
      await client.from('shared_checklist_members').delete().eq('list_id', listId).eq('guest_name', memberName);
    } catch (e) {
      print("Error removing checklist member: $e");
    }
  }

  static Future<List<SharedChecklist>> fetchUserSharedChecklists() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final response = await client.from('shared_checklist_members')
          .select('list_id, shared_checklists(name)')
          .eq('user_id', user.id);
      
      List<SharedChecklist> lists = [];
      for (var row in response as List) {
        final listId = row['list_id'];
        final listData = row['shared_checklists'];
        
        if (listData != null) {
          final membersResponse = await client.from('shared_checklist_members').select('guest_name, user_id').eq('list_id', listId);
          List<String> members = [];
          String? myMemberName;
          
          for (var mRow in membersResponse as List) {
            final mName = mRow['guest_name'] as String?;
            if (mName != null) {
              members.add(mName);
              if (mRow['user_id'] == user.id) {
                myMemberName = mName;
              }
            }
          }
          if (members.isEmpty) members.add('Tú');
          if (myMemberName == null && members.contains('Tú')) myMemberName = 'Tú';

          lists.add(SharedChecklist(
            id: listId,
            name: listData['name'] ?? 'Lista',
            members: members,
            items: [],
            logs: [],
            myMemberName: myMemberName,
          ));
        }
      }
      return lists;
    } catch (e) {
      print("Error fetching user shared checklists: $e");
      return [];
    }
  }

  static Future<List<SharedChecklistItem>> fetchSharedChecklistItems(String listId) async {
    try {
      final response = await client.from('shared_checklist_items').select().eq('list_id', listId).order('created_at', ascending: true);
      return (response as List).map((data) => SharedChecklistItem(
        id: data['id'],
        title: data['title'],
        isDone: data['is_done'],
        tags: (data['tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
        addedBy: data['added_by'] ?? 'Desconocido',
        createdAt: DateTime.parse(data['created_at']),
      )).toList();
    } catch (e) {
      print("Error fetching shared checklist items: $e");
      return [];
    }
  }

  static Stream<List<SharedChecklistItem>> streamSharedChecklistItems(String listId) {
    return client.from('shared_checklist_items').stream(primaryKey: ['id']).eq('list_id', listId).order('created_at', ascending: true).map(
      (list) => list.map((data) => SharedChecklistItem(
        id: data['id'],
        title: data['title'],
        isDone: data['is_done'],
        tags: (data['tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
        addedBy: data['added_by'] ?? 'Desconocido',
        createdAt: DateTime.parse(data['created_at']),
      )).toList(),
    );
  }

  static Future<List<SharedChecklistLog>> fetchSharedChecklistLogs(String listId) async {
    try {
      final response = await client.from('shared_checklist_logs').select().eq('list_id', listId).order('created_at', ascending: false);
      return (response as List).map((data) => SharedChecklistLog(
        id: data['id'],
        action: data['action'],
        userName: data['user_name'],
        itemTitle: data['item_title'],
        createdAt: DateTime.parse(data['created_at']),
      )).toList();
    } catch (e) {
      print("Error fetching shared checklist logs: $e");
      return [];
    }
  }

  static Stream<List<SharedChecklistLog>> streamSharedChecklistLogs(String listId) {
    return client.from('shared_checklist_logs').stream(primaryKey: ['id']).eq('list_id', listId).order('created_at', ascending: false).map(
      (list) => list.map((data) => SharedChecklistLog(
        id: data['id'],
        action: data['action'],
        userName: data['user_name'],
        itemTitle: data['item_title'],
        createdAt: DateTime.parse(data['created_at']),
      )).toList(),
    );
  }

  static Future<void> syncSharedChecklistItem(String listId, SharedChecklistItem item) async {
    try {
      await client.from('shared_checklist_items').upsert({
        'id': item.id,
        'list_id': listId,
        'title': item.title,
        'is_done': item.isDone,
        'tags': item.tags.join(','),
        'added_by': item.addedBy,
        'created_at': item.createdAt.toIso8601String(),
      });
    } catch (e) {
      print("Error syncing shared checklist item: $e");
    }
  }

  static Future<void> deleteSharedChecklistItem(String listId, String itemId) async {
    try {
      await client.from('shared_checklist_items').delete().eq('id', itemId).eq('list_id', listId);
    } catch (e) {
      print("Error deleting shared checklist item: $e");
    }
  }

  static Future<void> addSharedChecklistLog(String listId, SharedChecklistLog log) async {
    try {
      await client.from('shared_checklist_logs').insert({
        'list_id': listId,
        'action': log.action,
        'user_name': log.userName,
        'item_title': log.itemTitle,
      });
    } catch (e) {
      print("Error adding shared checklist log: $e");
    }
  }
}
