import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lost_found_model.dart';

class LostFoundProvider extends ChangeNotifier {
  static const _key = 'lost_found_items';

  List<LostFoundItem> _items = [];

  List<LostFoundItem> get items => List.unmodifiable(_items);

  List<LostFoundItem> get lostItems =>
      _items.where((i) => i.status == LostFoundStatus.lost).toList();

  List<LostFoundItem> get foundItems =>
      _items
          .where((i) =>
              i.status == LostFoundStatus.found ||
              i.status == LostFoundStatus.matched)
          .toList();

  List<LostFoundItem> get matchedItems =>
      _items.where((i) => i.status == LostFoundStatus.matched).toList();

  LostFoundProvider() {
    _load();
  }

  Future<void> addItem(LostFoundItem item) async {
    _items.insert(0, item);
    _tryAutoMatch(item);
    await _save();
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _save();
    notifyListeners();
  }

  /// Mark a lost item as found (status → found).
  Future<void> markAsFound(String id) async {
    _replaceStatus(id, LostFoundStatus.found);
    await _save();
    notifyListeners();
  }

  /// Fuzzy-match: same train + description keywords overlap → mark matched.
  void _tryAutoMatch(LostFoundItem newItem) {
    final opposite = newItem.status == LostFoundStatus.lost
        ? LostFoundStatus.found
        : LostFoundStatus.lost;

    final candidates =
        _items.where((i) => i.status == opposite && i.id != newItem.id);

    for (final candidate in candidates) {
      if (_descriptionMatch(newItem.description, candidate.description) &&
          newItem.trainName.toLowerCase() ==
              candidate.trainName.toLowerCase()) {
        newItem.matchedWithId = candidate.id;
        candidate.matchedWithId = newItem.id;
        // Mark both as matched by recreating them (immutable fields except matchedWithId)
        _replaceStatus(newItem.id, LostFoundStatus.matched);
        _replaceStatus(candidate.id, LostFoundStatus.matched);
        return;
      }
    }
  }

  bool _descriptionMatch(String a, String b) {
    final wordsA = a.toLowerCase().split(RegExp(r'\W+')).toSet();
    final wordsB = b.toLowerCase().split(RegExp(r'\W+')).toSet();
    final common =
        wordsA.intersection(wordsB).where((w) => w.length > 3).length;
    return common >= 2;
  }

  void _replaceStatus(String id, LostFoundStatus status) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final old = _items[idx];
    _items[idx] = LostFoundItem(
      id: old.id,
      reporterName: old.reporterName,
      trainName: old.trainName,
      coachNumber: old.coachNumber,
      description: old.description,
      status: status,
      reportedAt: old.reportedAt,
      matchedWithId: old.matchedWithId,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((e) => LostFoundItem.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_items.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }
}
