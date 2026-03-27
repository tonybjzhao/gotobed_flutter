import '../models/app_settings.dart';
import '../models/nightly_result.dart';

class BedtimeLogicService {
  BedtimeLogicService._();

  static final BedtimeLogicService instance = BedtimeLogicService._();

  static const int morningSummaryHour = 6;
  static const int snoozeMinutes = 10;
  static const int maxSnoozesPerNight = 3;

  DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String nightIdFromDate(DateTime date) {
    final normalized = dateOnly(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime interactionNightDate(DateTime now) {
    final today = dateOnly(now);
    if (now.hour < morningSummaryHour) {
      return today.subtract(const Duration(days: 1));
    }
    return today;
  }

  DateTime summaryNightDate(DateTime now) {
    final today = dateOnly(now);
    return today.subtract(const Duration(days: 1));
  }

  DateTime upcomingNotificationNightDate(DateTime now, AppSettings settings) {
    final today = dateOnly(now);
    final todayBedtime = _combine(
      today,
      settings.bedtimeHour,
      settings.bedtimeMinute,
    );
    if (now.isBefore(todayBedtime)) {
      return today;
    }
    return today.add(const Duration(days: 1));
  }

  NightlyResult buildNight({
    required AppSettings settings,
    required DateTime nightDate,
  }) {
    final date = dateOnly(nightDate);
    final bedtime = _combine(
      date,
      settings.bedtimeHour,
      settings.bedtimeMinute,
    );
    final gentleReminder = bedtime.subtract(
      Duration(minutes: settings.reminderLeadMinutes),
    );
    final strongReminder = bedtime;
    final graceDeadline = bedtime.add(
      const Duration(minutes: AppSettings.defaultGracePeriodMinutes),
    );

    return NightlyResult(
      nightId: nightIdFromDate(date),
      bedtimeIso: bedtime.toIso8601String(),
      gentleReminderIso: settings.gentleReminderEnabled
          ? gentleReminder.toIso8601String()
          : null,
      strongReminderIso: strongReminder.toIso8601String(),
      graceDeadlineIso: graceDeadline.toIso8601String(),
      nextReminderAtIso:
          (settings.gentleReminderEnabled ? gentleReminder : strongReminder)
              .toIso8601String(),
    );
  }

  NightlyResult syncNightWithSettings({
    required NightlyResult? existing,
    required AppSettings settings,
    required DateTime nightDate,
    required DateTime now,
  }) {
    final rebuilt = buildNight(settings: settings, nightDate: nightDate);
    if (existing == null) {
      return rebuilt;
    }

    final keepSnoozeSchedule =
        existing.snoozeCount > 0 && existing.nextReminderAt.isAfter(now);

    return existing.copyWith(
      bedtimeIso: rebuilt.bedtimeIso,
      gentleReminderIso: rebuilt.gentleReminderIso,
      clearGentleReminderIso: rebuilt.gentleReminderIso == null,
      strongReminderIso: rebuilt.strongReminderIso,
      graceDeadlineIso: rebuilt.graceDeadlineIso,
      nextReminderAtIso: keepSnoozeSchedule
          ? existing.nextReminderAtIso
          : rebuilt.nextReminderAtIso,
    );
  }

  NightlyResult markConfirmed(NightlyResult night, DateTime confirmedAt) {
    return night.copyWith(confirmedAtIso: confirmedAt.toIso8601String());
  }

  NightlyResult applySnooze(NightlyResult night, DateTime now) {
    final snoozeTime = now.add(const Duration(minutes: snoozeMinutes));
    return night.copyWith(
      nextReminderAtIso: snoozeTime.toIso8601String(),
      snoozeCount: night.snoozeCount + 1,
    );
  }

  bool canSnooze(NightlyResult night, DateTime now) {
    return night.confirmedAt == null &&
        !night.isResolved &&
        night.snoozeCount < maxSnoozesPerNight &&
        !now.isBefore(night.nextReminderAt);
  }

  bool isReminderActive(NightlyResult night, DateTime now) {
    return canSnooze(night, now);
  }

  bool shouldResolveMorningSummary(DateTime now) {
    return now.hour >= morningSummaryHour;
  }

  NightlyResult resolveNight(NightlyResult night, DateTime resolvedAt) {
    final confirmedAt = night.confirmedAt;
    final wasSuccessful =
        confirmedAt != null && !confirmedAt.isAfter(night.graceDeadline);
    return night.copyWith(
      resolvedAtIso: resolvedAt.toIso8601String(),
      wasSuccessful: wasSuccessful,
    );
  }

  DateTime _combine(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
