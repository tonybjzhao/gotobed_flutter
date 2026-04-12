import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/nightly_result.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _settingsKey = 'sleep_nudger_settings';
  static const String _nightlyResultsKey = 'sleep_nudger_nightly_results';
  static const String _streakKey = 'sleep_nudger_current_streak';

  SharedPreferences? _cachedPrefs;

  Future<void> initialize() async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _prefs async {
    await initialize();
    return _cachedPrefs!;
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await _prefs;
    return prefs.containsKey(_settingsKey);
  }

  Future<AppSettings?> loadSettings() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AppSettings.fromJson(raw);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_settingsKey, settings.toJson());
  }

  Future<int> loadCurrentStreak() async {
    final prefs = await _prefs;
    return prefs.getInt(_streakKey) ?? 0;
  }

  Future<void> saveCurrentStreak(int streak) async {
    final prefs = await _prefs;
    await prefs.setInt(_streakKey, streak);
  }

  Future<List<NightlyResult>> loadNightlyResults() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_nightlyResultsKey);
    if (raw == null || raw.isEmpty) {
      return <NightlyResult>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => NightlyResult.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<NightlyResult?> loadNightlyResult(String nightId) async {
    final results = await loadNightlyResults();
    for (final result in results) {
      if (result.nightId == nightId) {
        return result;
      }
    }
    return null;
  }

  Future<void> saveNightlyResult(NightlyResult result) async {
    final results = await loadNightlyResults();
    final updated = <NightlyResult>[
      for (final existing in results)
        if (existing.nightId != result.nightId) existing,
      result,
    ];

    updated.sort((a, b) => b.nightId.compareTo(a.nightId));
    final trimmed = updated.take(14).toList();

    final prefs = await _prefs;
    await prefs.setString(
      _nightlyResultsKey,
      jsonEncode(trimmed.map((item) => item.toMap()).toList()),
    );
  }
}
