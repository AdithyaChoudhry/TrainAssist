import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medical_profile_model.dart';

class MedicalProfileProvider extends ChangeNotifier {
  static const _key = 'medical_profile';

  MedicalProfile _profile = MedicalProfile();
  bool _isLoading = false;

  MedicalProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasProfile => !_profile.isEmpty;

  MedicalProfileProvider() {
    _load();
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(profile.toJson()));
      _profile = profile;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _profile =
            MedicalProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _profile = MedicalProfile();
    notifyListeners();
  }
}
