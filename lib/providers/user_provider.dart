import 'package:flutter/material.dart';
import 'package:gymw3dlat/services/supabase_service.dart';

class UserProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _supabaseService.getCurrentUser();
      if (user != null) {
        _userData = user;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _userData = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
