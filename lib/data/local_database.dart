import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/checklist_item.dart';
import 'supabase_repository.dart';

/// SQLite local database for offline-first personal data persistence.
/// Supabase is NOT used for personal data — only for shared expenses.
class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'billince.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            module TEXT NOT NULL,
            attached_file_name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_lists (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            date_created TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE checklist_items (
            id TEXT PRIMARY KEY,
            list_id TEXT NOT NULL,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0.0,
            FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE calendar_events (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            date_time TEXT NOT NULL,
            end_date_time TEXT,
            category TEXT NOT NULL DEFAULT 'personal',
            is_all_day INTEGER NOT NULL DEFAULT 0,
            is_done INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Expenses ────────────────────────────────────────────────

  static Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'module': expense.module,
      'attached_file_name': expense.attachedFileName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Backup to cloud if authenticated
    SupabaseRepository.syncExpense(expense);
  }

  static Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map((r) => Expense(
      id: r['id'] as String,
      title: r['title'] as String,
      amount: r['amount'] as double,
      date: DateTime.parse(r['date'] as String),
      module: r['module'] as String,
      attachedFileName: r['attached_file_name'] as String?,
    )).toList();
  }

  static Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    
    // Remove from cloud if authenticated
    SupabaseRepository.deleteExpense(id);
  }

  // ── Shopping Lists ──────────────────────────────────────────

  static Future<void> insertShoppingList(ShoppingList list) async {
    final db = await database;
    await db.insert('shopping_lists', {
      'id': list.id,
      'title': list.title,
      'date_created': list.dateCreated.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    for (final item in list.items) {
      await db.insert('checklist_items', {
        'id': item.id,
        'list_id': list.id,
        'title': item.title,
        'is_done': item.isDone ? 1 : 0,
        'price': item.price,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<ShoppingList>> getShoppingLists() async {
    final db = await database;
    final listRows = await db.query('shopping_lists', orderBy: 'date_created DESC');
    final lists = <ShoppingList>[];

    for (final row in listRows) {
      final itemRows = await db.query('checklist_items',
        where: 'list_id = ?', whereArgs: [row['id']],
      );
      lists.add(ShoppingList(
        id: row['id'] as String,
        title: row['title'] as String,
        dateCreated: DateTime.parse(row['date_created'] as String),
        items: itemRows.map((i) => ChecklistItem(
          id: i['id'] as String,
          title: i['title'] as String,
          isDone: (i['is_done'] as int) == 1,
          price: (i['price'] as num).toDouble(),
        )).toList(),
      ));
    }
    return lists;
  }

  static Future<void> deleteShoppingList(String id) async {
    final db = await database;
    await db.delete('checklist_items', where: 'list_id = ?', whereArgs: [id]);
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateChecklistItem(ChecklistItem item, String listId) async {
    final db = await database;
    await db.update('checklist_items', {
      'title': item.title,
      'is_done': item.isDone ? 1 : 0,
      'price': item.price,
    }, where: 'id = ?', whereArgs: [item.id]);
  }

  static Future<void> insertChecklistItem(ChecklistItem item, String listId) async {
    final db = await database;
    await db.insert('checklist_items', {
      'id': item.id,
      'list_id': listId,
      'title': item.title,
      'is_done': item.isDone ? 1 : 0,
      'price': item.price,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteChecklistItem(String id) async {
    final db = await database;
    await db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Calendar Events ─────────────────────────────────────────
  // (stub for future persistence — currently in-memory via AppData)
}
