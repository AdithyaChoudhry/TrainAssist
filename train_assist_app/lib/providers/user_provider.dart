import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores user accounts as JSON in SharedPreferences.
/// Key: "accounts"  →  Map<username, {name, password}>
/// Key: "current_user"  →  username of the logged-in user
class UserProvider extends ChangeNotifier {
  static const _accountsKey = 'accounts';
  static const _currentUserKey = 'current_user';

  String? _userName;         // display name
  String? _userUsername;     // login username
  bool _isLoading = false;

  String? get userName => _userName;
  String? get userUsername => _userUsername;
  bool get isUserSet => _userName != null && _userName!.isNotEmpty;
  bool get isLoading => _isLoading;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  Future<void> loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getString(_currentUserKey);
      if (current != null) {
        final accounts = _decodeAccounts(prefs);
        if (accounts.containsKey(current)) {
          _userUsername = current;
          _userName = accounts[current]['name'] as String;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string.
  Future<String?> register({
    required String name,
    required String username,
    required String password,
  }) async {
    if (name.trim().isEmpty) return 'Name cannot be empty';
    if (username.trim().isEmpty) return 'Username cannot be empty';
    if (password.length < 4) return 'Password must be at least 4 characters';

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = _decodeAccounts(prefs);

      if (accounts.containsKey(username.trim())) {
        return 'Username already taken';
      }

      accounts[username.trim()] = {
        'name': name.trim(),
        'password': password,
      };

      await prefs.setString(_accountsKey, jsonEncode(accounts));
      await prefs.setString(_currentUserKey, username.trim());

      _userUsername = username.trim();
      _userName = name.trim();
      notifyListeners();
      return null; // success
    } catch (e) {
      return 'Registration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string.
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) return 'Username cannot be empty';
    if (password.isEmpty) return 'Password cannot be empty';

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = _decodeAccounts(prefs);

      final entry = accounts[username.trim()];
      if (entry == null) return 'Username not found';
      if (entry['password'] != password) return 'Incorrect password';

      await prefs.setString(_currentUserKey, username.trim());
      _userUsername = username.trim();
      _userName = entry['name'] as String;
      notifyListeners();
      return null; // success
    } catch (e) {
      return 'Login failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> clearUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      _userName = null;
      _userUsername = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing user: $e');
    }
  }

  // ── Legacy helper kept for existing welcomeScreen compat ─────────────────
  Future<void> saveUserName(String name) async {
    // If called from old welcome screen, treat as a quick register with name=username.
    await register(name: name, username: name.toLowerCase().replaceAll(' ', '_'), password: 'pass123');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _decodeAccounts(SharedPreferences prefs) {
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
