import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing user information
/// Handles storing and retrieving user name from local storage
class UserProvider extends ChangeNotifier {
  static const String _userNameKey = 'user_name';
  
  String? _userName;
  
  String? get userName => _userName;
  
  /// Check if user name is set and not empty
  bool get isUserSet => _userName != null && _userName!.isNotEmpty;
  
  /// Load user name from SharedPreferences
  Future<void> loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString(_userNameKey);
      notifyListeners();
    } catch (e) {
      print('Error loading user name: $e');
    }
  }
  
  /// Save user name to SharedPreferences
  Future<void> saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      _userName = name;
      notifyListeners();
    } catch (e) {
      print('Error saving user name: $e');
      rethrow;
    }
  }
  
  /// Clear user name (logout)
  Future<void> clearUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userNameKey);
      _userName = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing user name: $e');
    }
  }
}
