import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/bedtime_tone.dart';
import '../models/nightly_result.dart';
import 'bedtime_message_engine.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  factory NotificationService() => instance;

  void Function(List<dynamic>)? onNewPosts;
  void Function(dynamic, List<dynamic>)? onNewCommentsForPost;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final BedtimeMessageEngine _messageEngine = BedtimeMessageEngine();

  bool _initialized = false;

  bool get _supportsNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized || !_supportsNotifications) {
      return;
    }

    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );
  }

  Future<void> scheduleNightPlan({
    required AppSettings settings,
    required NightlyResult night,
    required DateTime now,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();
    await cancelNightNotifications(night.nightId);

    if (night.confirmedAt != null || night.isResolved) {
      return;
    }

    final gentleAt = night.gentleReminderAt;
    if (settings.gentleReminderEnabled &&
        gentleAt != null &&
        gentleAt.isAfter(now)) {
      final gentleMessage = _messageEngine.selectMessageForTone(
        BedtimeTone.gentle,
      );
      await _scheduleNotification(
        id: _notificationId(night.nightId, 1),
        title: gentleMessage.title,
        body: gentleMessage.subtitle ?? 'A gentle nudge before bedtime.',
        when: gentleAt,
        strong: false,
        soundEnabled: settings.soundVibrationEnabled,
        payload: _payloadFor(night.nightId, 'gentle'),
      );
    }

    if (night.strongReminderAt.isAfter(now)) {
      final bedtimeMessage = _messageEngine.selectMessageForTone(
        BedtimeTone.neutral,
      );
      await _scheduleNotification(
        id: _notificationId(night.nightId, 2),
        title: bedtimeMessage.title,
        body: bedtimeMessage.subtitle ?? 'Tonight can still end well.',
        when: night.strongReminderAt,
        strong: true,
        soundEnabled: settings.soundVibrationEnabled,
        payload: _payloadFor(night.nightId, 'strong'),
      );
    }
  }

  Future<void> scheduleSnoozeReminder({
    required AppSettings settings,
    required NightlyResult night,
    required DateTime now,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();
    await cancelNightNotifications(night.nightId);

    if (night.confirmedAt != null || night.isResolved) {
      return;
    }

    if (night.nextReminderAt.isAfter(now)) {
      final snoozeMessage = _messageEngine.selectMessageForTone(
        BedtimeTone.firm,
      );
      await _scheduleNotification(
        id: _notificationId(night.nightId, 3),
        title: snoozeMessage.title,
        body: snoozeMessage.subtitle ?? 'Take the cue and head to bed.',
        when: night.nextReminderAt,
        strong: true,
        soundEnabled: settings.soundVibrationEnabled,
        payload: _payloadFor(night.nightId, 'snooze'),
      );
    }
  }

  Future<void> cancelNightNotifications(String nightId) async {
    if (!_supportsNotifications) {
      return;
    }

    await _plugin.cancel(id: _notificationId(nightId, 1));
    await _plugin.cancel(id: _notificationId(nightId, 2));
    await _plugin.cancel(id: _notificationId(nightId, 3));
  }

  Future<void> _createChannels() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'sleep_nudger_gentle',
        'Gentle reminders',
        description: 'Calm reminders before bedtime.',
        importance: Importance.defaultImportance,
      ),
    );

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'sleep_nudger_strong',
        'Bedtime reminders',
        description: 'Stronger nudges when bedtime arrives.',
        importance: Importance.high,
      ),
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required bool strong,
    required bool soundEnabled,
    required String payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        strong ? 'sleep_nudger_strong' : 'sleep_nudger_gentle',
        strong ? 'Bedtime reminders' : 'Gentle reminders',
        channelDescription: strong
            ? 'Stronger nudges when bedtime arrives.'
            : 'Calm reminders before bedtime.',
        importance: strong ? Importance.high : Importance.defaultImportance,
        priority: strong ? Priority.high : Priority.defaultPriority,
        playSound: soundEnabled,
        enableVibration: soundEnabled,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: soundEnabled,
        presentBadge: false,
      ),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  int _notificationId(String nightId, int slot) {
    final compact = nightId.replaceAll('-', '');
    return int.parse(compact) * 10 + slot;
  }

  String _payloadFor(String nightId, String stage) {
    return jsonEncode(<String, String>{'nightId': nightId, 'stage': stage});
  }

  // Legacy compatibility hooks for the previous repo.
  void bindPostStreams({
    required Stream<List<dynamic>>? nearby,
    required Stream<List<dynamic>>? visit,
  }) {}

  void unbindPostStreams() {}

  void startChecking() {}

  void stopChecking() {}
}
