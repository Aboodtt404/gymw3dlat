import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';

/// Provider class that manages user authentication and profile data
class UserProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  User? _user;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._supabase);

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  // Getter for user data as a Map
  Map<String, dynamic>? get userData => _user?.toJson();

  // Initialize user data on app start
  Future<void> initializeUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final session = _supabase.auth.currentSession;
      if (session != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('auth_id', session.user.id)
            .single();

        if (userData != null) {
          _user = User.fromJson(Map<String, dynamic>.from(userData));
        }
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user data from Supabase
  Future<void> fetchUserData() async {
    try {
      _isLoading = true;
      _clearError();

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      final data = await _supabase
          .from('users')
          .select()
          .eq('auth_id', session.user.id)
          .single();

      if (data == null) {
        throw Exception('User profile not found');
      }

      _user = User.fromJson(data);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      _isLoading = true;
      _clearError();

      if (_user == null) throw Exception('No user logged in');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      // Update user data in Supabase
      final updatedData = await _supabase
          .from('users')
          .update({
            if (name != null) 'name': name,
            if (email != null) 'email': email,
            if (photoUrl != null) 'photo_url': photoUrl,
          })
          .eq('auth_id', session.user.id)
          .select()
          .single();

      if (updatedData == null) {
        throw Exception('Failed to update user profile');
      }

      _user = User.fromJson(updatedData);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      _clearError();

      if (_user == null) throw Exception('No user logged in');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      final userId = session.user.id;

      // Delete user data from Supabase
      await _supabase.from('users').delete().eq('id', userId);

      // Delete auth user
      await _supabase.auth.admin.deleteUser(userId);

      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error deleting account: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in a user with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        if (userData == null) {
          throw Exception('User profile not found');
        }

        _user = User.fromJson(Map<String, dynamic>.from(userData));
        _error = null;
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new user account and profile
  Future<void> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final now = DateTime.now().toIso8601String();
        final Map<String, dynamic> userData = {
          'auth_id': response.user!.id,
          'email': response.user!.email ?? email,
          'name': name,
          'created_at': now,
          'updated_at': now,
        };

        final insertedData =
            await _supabase.from('users').insert(userData).select().single();

        if (insertedData == null) {
          throw Exception('Failed to create user profile');
        }

        _user = User.fromJson(insertedData);
        _error = null;
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
