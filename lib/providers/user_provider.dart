import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'dart:typed_data';

/// Provider class that manages user authentication and profile data
class UserProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._supabase);

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  // Getter for user data as a Map
  Map<String, dynamic>? get userData => _user?.toJson();

  // Upload profile image to Supabase storage
  Future<void> uploadProfileImage(String path, Uint8List bytes) async {
    try {
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Get public URL for uploaded image
  String getPublicUrl(String path) {
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

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
            .maybeSingle();

        if (userData != null) {
          _user = UserModel.fromJson(Map<String, dynamic>.from(userData));
        } else {
          // Create user profile if it doesn't exist
          await _createUserProfile(session.user);
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

  // Create user profile if it doesn't exist
  Future<void> _createUserProfile(User user) async {
    try {
      final now = DateTime.now().toIso8601String();
      final Map<String, dynamic> userData = {
        'auth_id': user.id,
        'email': user.email ?? '',
        'name':
            user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
        'photo_url': user.userMetadata?['avatar_url'] ?? null,
        'created_at': now,
        'updated_at': now,
      };

      final insertedData =
          await _supabase.from('users').insert(userData).select().single();

      if (insertedData != null) {
        _user = UserModel.fromJson(insertedData);
      }
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      _error = e.toString();
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
          .maybeSingle();

      if (data == null) {
        await _createUserProfile(session.user);
      } else {
        _user = UserModel.fromJson(data);
      }

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
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('auth_id', session.user.id)
          .select()
          .single();

      if (updatedData == null) {
        throw Exception('Failed to update user profile');
      }

      _user = UserModel.fromJson(updatedData);
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

      // Delete user data from Supabase
      await _supabase.from('users').delete().eq('auth_id', session.user.id);

      // Delete auth user
      await _supabase.auth.admin.deleteUser(session.user.id);

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
      _clearError();
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // First try to fetch existing user data
        final userData = await _supabase
            .from('users')
            .select()
            .eq('auth_id', response.user!.id)
            .maybeSingle();

        if (userData == null) {
          // If no user data exists, create a new profile
          await _createUserProfile(response.user!);
        } else {
          // If user data exists, initialize the user model
          _user = UserModel.fromJson(Map<String, dynamic>.from(userData));
        }

        // Clear any previous errors
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      _error = e.toString();
      notifyListeners();
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
      _clearError();
      notifyListeners();

      final response =
          await _supabase.auth.signUp(email: email, password: password, data: {
        'name': name // Store name in user metadata
      });

      if (response.user != null) {
        // Create user profile with the provided name
        final now = DateTime.now().toIso8601String();
        final Map<String, dynamic> userData = {
          'auth_id': response.user!.id,
          'email': email,
          'name': name, // Use provided name instead of email
          'photo_url': null,
          'created_at': now,
          'updated_at': now,
        };

        final insertedData =
            await _supabase.from('users').insert(userData).select().single();

        if (insertedData != null) {
          _user = UserModel.fromJson(insertedData);
          notifyListeners();
        }

        _error = null;
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
      _error = e.toString();
      notifyListeners();
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

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
