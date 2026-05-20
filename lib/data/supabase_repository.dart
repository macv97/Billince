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
}
