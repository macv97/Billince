import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billince/data/local_database.dart';
import 'package:billince/data/app_data.dart';
import 'dart:io';

Future<void> setupTestEnvironment() async {
  // Initialize SQLite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});


  // Load actual .env or mock if needed
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If running in CI without .env
    dotenv.env['SUPABASE_URL'] = 'https://dummy.supabase.co';
    dotenv.env['SUPABASE_ANON_KEY'] = 'dummy';
  }

  // Initialize Supabase with dummy values to prevent StateError
  try {
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy',
    );
  } catch (e) {
    // Already initialized
  }

  // Clear AppData to ensure clean state
  AppData.expenses.clear();
  AppData.shoppingLists.clear();
  AppData.calendarEvents.clear();
  AppData.sharedGroups.clear();
  AppData.sharedChecklists.clear();

  // Clear SQLite Database for tests
  final dbPath = await getDatabasesPath();
  final path = '$dbPath/billince.db';
  final file = File(path);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (e) {
      // Ignore file lock errors in parallel tests
    }
  }
}
