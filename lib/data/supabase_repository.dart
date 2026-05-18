import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase repository — ONLY for shared/collaborative expenses.
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
  // TODO: Implement real Supabase tables for shared groups
  // - Create/join groups via invite link or QR
  // - Sync expenses within a group in real-time
  // - Settle debts between members
}
