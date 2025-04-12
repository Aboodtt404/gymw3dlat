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
      print('Attempting to sign in with email: $email'); // Debug log

      final response = await _staticClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Sign in successful: ${response.user?.email}'); // Debug log
      return response;
    } catch (e, stackTrace) {
      print('Error signing in: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log

      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or password. Please try again.');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception('Please verify your email address before logging in.');
      }
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  static Future<AuthResponse?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      print('Attempting to create user with email: $email'); // Debug log

      final response = await _staticClient.auth.signUp(
        email: email,
        password: password,
      );

      print('Auth signup response: $response'); // Debug log

      if (response.user != null) {
        print('User created, attempting to insert profile...'); // Debug log

        // Create user profile in Supabase
        await _staticClient.from('users').insert({
          'auth_id': response.user!.id,
          'name': name,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        }).select(); // Add select() to get response

        print('User profile created successfully'); // Debug log
      }

      return response;
    } catch (e, stackTrace) {
      print('Error creating user: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log

      if (e.toString().contains('User already registered')) {
        throw Exception(
            'This email is already registered. Please try logging in instead.');
      } else if (e.toString().contains('duplicate key')) {
        throw Exception(
            'This email is already in use. Please try another email.');
      } else if (e.toString().contains('Invalid email')) {
        throw Exception('Please enter a valid email address.');
      } else if (e.toString().contains('Password')) {
        throw Exception('Password should be at least 6 characters long.');
      }

      throw Exception('Failed to create account: ${e.toString()}');
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
