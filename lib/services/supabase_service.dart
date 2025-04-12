import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseClient get _staticClient => Supabase.instance.client;
  final SupabaseClient _client = Supabase.instance.client;

  static Future<void> initializeSupabase() async {
    try {
      await dotenv.load(fileName: ".env");

      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      );
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  static Future<AuthResponse?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _staticClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  static Future<AuthResponse?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _staticClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile in Supabase
        await _staticClient.from('users').insert({
          'auth_id': response.user!.id,
          'name': name,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final response = await _client
            .from('users')
            .select()
            .eq('auth_id', user.id)
            .single();
        return response;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  static User? get currentUser => _staticClient.auth.currentUser;
  static Stream<AuthState> get authStateChanges =>
      _staticClient.auth.onAuthStateChange;
  static SupabaseClient get client => _staticClient;
}
