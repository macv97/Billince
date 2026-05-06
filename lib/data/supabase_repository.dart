import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'app_data.dart';
import '../models/expense.dart';
import '../models/checklist_item.dart';

class SupabaseRepository {
  static final SupabaseClient client = Supabase.instance.client;

  // -- User Session --
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // -- Auth Methods --
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
    AppData.expenses.clear();
    AppData.shoppingLists.clear();
    AppData.currency = '€';
  }

  // -- Load User Settings --
  static Future<void> loadUserSettings() async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      final data = await client.from('user_settings').select().eq('id', user.id).maybeSingle();
      if (data != null && data['currency'] != null) {
        AppData.currency = data['currency'];
      } else {
        // Create initial settings if not exists
        await client.from('user_settings').insert({
          'id': user.id,
          'currency': '€',
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  static Future<void> updateCurrency(String currency) async {
    final user = currentUser;
    if (user == null) return;
    
    AppData.currency = currency;
    try {
      await client.from('user_settings').upsert({
        'id': user.id,
        'currency': currency,
      });
    } catch (e) {
      debugPrint('Error updating currency: $e');
    }
  }

  // -- Load Data --
  static Future<void> loadInitialData() async {
    final user = currentUser;
    if (user == null) return;
    
    // Load Expenses
    try {
      final expensesData = await client.from('expenses').select().order('date', ascending: false);
      AppData.expenses.clear();
      for (var row in expensesData) {
        AppData.expenses.add(Expense(
          id: row['id'],
          title: row['title'],
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['date']),
          module: row['module'] ?? 'General',
          attachedFileName: row['attached_file_name'],
        ));
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }

    // Load Shopping Lists
    try {
      final listsData = await client.from('shopping_lists').select().order('created_at', ascending: false);
      AppData.shoppingLists.clear();
      for (var row in listsData) {
        final itemsData = await client.from('checklist_items').select().eq('list_id', row['id']).order('created_at');
        List<ChecklistItem> items = itemsData.map((itemRow) => ChecklistItem(
          id: itemRow['id'],
          title: itemRow['title'],
          isDone: itemRow['is_done'],
        )).toList();

        AppData.shoppingLists.add(ShoppingList(
          id: row['id'],
          title: row['title'],
          items: items,
          dateCreated: DateTime.parse(row['created_at']),
        ));
      }
    } catch (e) {
      debugPrint('Error loading lists: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // ── GEMINI AI VIA EDGE FUNCTION (Server-side, secure) ────
  // ──────────────────────────────────────────────────────────

  /// Calls the gemini-proxy Edge Function.
  /// [prompt] - The text prompt for Gemini.
  /// [imageBytes] - Optional image bytes for multimodal analysis.
  /// Returns the raw text response from Gemini, or null on error.
  static Future<String?> callGemini({
    required String prompt,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (!isAuthenticated) return null;

    try {
      final body = <String, dynamic>{
        'prompt': prompt,
      };

      if (imageBytes != null) {
        body['imageBase64'] = base64Encode(imageBytes);
        body['mimeType'] = mimeType;
      }

      debugPrint('[Gemini Proxy] Calling edge function...');

      final response = await client.functions.invoke(
        'gemini-proxy',
        body: body,
      );

      debugPrint('[Gemini Proxy] Status: ${response.status}');
      debugPrint('[Gemini Proxy] Data type: ${response.data.runtimeType}');
      debugPrint('[Gemini Proxy] Data: ${response.data}');

      final data = response.data;
      
      // Handle string response (needs JSON decode)
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map && parsed.containsKey('result')) {
            return parsed['result'] as String?;
          }
        } catch (_) {
          return data; // Return raw string if not JSON
        }
      }
      
      // Handle map response
      if (data is Map && data.containsKey('result')) {
        return data['result'] as String?;
      }
      
      debugPrint('[Gemini Proxy] Unexpected response format');
      return null;
    } on FunctionException catch (e) {
      // Extract the user-friendly error message from the Edge Function
      final details = e.details;
      String errorMsg = 'Error del servicio de IA';
      if (details is Map && details.containsKey('error')) {
        errorMsg = details['error'].toString();
      }
      debugPrint('[Gemini Proxy] FunctionException: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[Gemini Proxy] Exception: $e');
      throw Exception('No se pudo conectar con el servicio de IA.');
    }
  }

  // -- Add Expense --
  static Future<Expense?> addExpense(Expense expense) async {
    final user = currentUser;
    if (user == null) {
      AppData.expenses.insert(0, expense); // Fallback offline/anon
      return expense;
    }
    
    try {
      final data = await client.from('expenses').insert({
        'user_id': user.id,
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'module': expense.module,
        'attached_file_name': expense.attachedFileName,
      }).select().single();
      
      final savedExpense = Expense(
        id: data['id'],
        title: data['title'],
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date']),
        module: data['module'],
        attachedFileName: data['attached_file_name'],
      );
      AppData.expenses.insert(0, savedExpense);
      return savedExpense;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return null;
    }
  }

  // -- Create Shopping List with items --
  static Future<ShoppingList?> createShoppingListWithItems(String title, List<String> itemNames) async {
    final user = currentUser;
    if (user == null) {
       // Fallback offline/anon
       final newList = ShoppingList(id: DateTime.now().toIso8601String(), title: title, items: itemNames.map((n) => ChecklistItem(id: DateTime.now().microsecondsSinceEpoch.toString(), title: n, isDone: true)).toList(), dateCreated: DateTime.now());
       AppData.shoppingLists.add(newList);
       return newList;
    }

    try {
      final listData = await client.from('shopping_lists').insert({
        'user_id': user.id,
        'title': title,
      }).select().single();

      final listId = listData['id'];
      
      List<ChecklistItem> items = [];
      for (String itemName in itemNames) {
        final itemData = await client.from('checklist_items').insert({
          'list_id': listId,
          'user_id': user.id,
          'title': itemName,
          'is_done': true, // Auto-marked as done for scanned tickets
        }).select().single();
        
        items.add(ChecklistItem(
          id: itemData['id'],
          title: itemData['title'],
          isDone: itemData['is_done'],
        ));
      }

      final newList = ShoppingList(
        id: listId,
        title: listData['title'],
        items: items,
        dateCreated: DateTime.parse(listData['created_at']),
      );
      AppData.shoppingLists.add(newList);
      return newList;
    } catch (e) {
      debugPrint('Error creating shopping list: $e');
      return null;
    }
  }

}
