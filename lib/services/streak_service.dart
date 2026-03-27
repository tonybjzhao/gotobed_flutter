import '../models/app_settings.dart';
import '../models/nightly_result.dart';
import 'bedtime_logic_service.dart';
import 'storage_service.dart';

class StreakService {
  StreakService._();

  static final StreakService instance = StreakService._();

  final StorageService _storageService = StorageService.instance;
  final BedtimeLogicService _logicService = BedtimeLogicService.instance;

  Future<NightlyResult?> resolveMorningSummaryIfNeeded({
    required AppSettings settings,
    required DateTime now,
  }) async {
    if (!_logicService.shouldResolveMorningSummary(now)) {
      return null;
    }

    final summaryDate = _logicService.summaryNightDate(now);
    final summaryNightId = _logicService.nightIdFromDate(summaryDate);

    final storedNight = await _storageService.loadNightlyResult(summaryNightId);
    final syncedNight = _logicService.syncNightWithSettings(
      existing: storedNight,
      settings: settings,
      nightDate: summaryDate,
      now: now,
    );

    final resolvedNight = syncedNight.isResolved
        ? syncedNight
        : _logicService.resolveNight(syncedNight, now);

    if (!syncedNight.isResolved) {
      final currentStreak = await _storageService.loadCurrentStreak();
      final nextStreak = resolvedNight.wasSuccessful == true
          ? currentStreak + 1
          : 0;
      await _storageService.saveCurrentStreak(nextStreak);
    }

    await _storageService.saveNightlyResult(resolvedNight);

    if (resolvedNight.summaryShown) {
      return null;
    }

    return resolvedNight;
  }
}
