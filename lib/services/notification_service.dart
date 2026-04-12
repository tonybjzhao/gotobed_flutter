import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  final Random _random = Random();

  static const String _gentleDefaultChannelId = 'sleep_nudger_gentle';
  static const String _strongDefaultChannelId = 'sleep_nudger_strong';
  static const String _testDefaultChannelId = 'sleep_nudger_test';
  static const List<String> _softVoiceSoundResources = <String>[
    'sleep_1',
    'sleep_2',
    'sleep_3',
    'sleep_4',
    'sleep_5',
  ];

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

    await scheduleGentleReminder(settings: settings, night: night, now: now);
    await scheduleBedtimeReminder(settings: settings, night: night, now: now);
    await scheduleOverdueReminder(settings: settings, night: night, now: now);
  }

  Future<void> rescheduleFromSettings({
    required AppSettings settings,
    required NightlyResult upcomingNight,
    required DateTime now,
  }) async {
    await scheduleNightPlan(settings: settings, night: upcomingNight, now: now);
  }

  Future<void> scheduleGentleReminder({
    required AppSettings settings,
    required NightlyResult night,
    required DateTime now,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();

    final gentleAt = night.gentleReminderAt;
    if (!settings.gentleReminderEnabled ||
        gentleAt == null ||
        !gentleAt.isAfter(now)) {
      return;
    }

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
      soundProfile: settings.reminderSoundProfile,
      payload: _payloadFor(night.nightId, 'gentle'),
    );
  }

  Future<void> scheduleBedtimeReminder({
    required AppSettings settings,
    required NightlyResult night,
    required DateTime now,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();

    if (!night.strongReminderAt.isAfter(now)) {
      return;
    }

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
      soundProfile: settings.reminderSoundProfile,
      payload: _payloadFor(night.nightId, 'strong'),
    );
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
        soundProfile: settings.reminderSoundProfile,
        payload: _payloadFor(night.nightId, 'snooze'),
      );
    }
  }

  Future<void> scheduleOverdueReminder({
    required AppSettings settings,
    required NightlyResult night,
    required DateTime now,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();

    final overdueAt = night.strongReminderAt.add(const Duration(minutes: 15));
    if (!overdueAt.isAfter(now) ||
        !overdueAt.isBefore(night.graceDeadline) ||
        night.confirmedAt != null ||
        night.isResolved) {
      return;
    }

    final overdueMessage = _messageEngine.selectMessageForTone(
      BedtimeTone.firm,
    );
    await _scheduleNotification(
      id: _notificationId(night.nightId, 4),
      title: overdueMessage.title,
      body: overdueMessage.subtitle ?? 'Just 5 more minutes… or sleep?',
      when: overdueAt,
      strong: true,
      soundEnabled: settings.soundVibrationEnabled,
      soundProfile: settings.reminderSoundProfile,
      payload: _payloadFor(night.nightId, 'overdue'),
    );
  }

  Future<void> cancelNightNotifications(String nightId) async {
    if (!_supportsNotifications) {
      return;
    }

    await _plugin.cancel(id: _notificationId(nightId, 1));
    await _plugin.cancel(id: _notificationId(nightId, 2));
    await _plugin.cancel(id: _notificationId(nightId, 3));
    await _plugin.cancel(id: _notificationId(nightId, 4));
  }

  Future<void> cancelTonightReminders(NightlyResult night) {
    return cancelNightNotifications(night.nightId);
  }

  Future<void> scheduleTestNotification({
    required bool soundEnabled,
    ReminderSoundProfile soundProfile = ReminderSoundProfile.system,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();

    final when = DateTime.now().add(const Duration(seconds: 5));
    final useVoice =
      soundEnabled && soundProfile == ReminderSoundProfile.softVoice;
    final voiceVariantIndex = useVoice ? _voiceVariantForSchedule() : null;
    final voiceVariant = voiceVariantIndex == null ? null : voiceVariantIndex + 1;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
      useVoice
        ? _voiceChannelId(strong: true, test: true, variant: voiceVariant!)
        : _testDefaultChannelId,
        useVoice ? 'Test reminder (voice)' : 'Test reminder',
        channelDescription: useVoice
            ? 'Test reminder with soft voice sound.'
            : 'Test reminder with system sound.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: soundEnabled,
        enableVibration: soundEnabled,
        sound: useVoice
            ? RawResourceAndroidNotificationSound(
                _softVoiceSoundResources[voiceVariantIndex!],
              )
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: soundEnabled,
        presentBadge: false,
        sound: useVoice ? _iosSoundFileName(voiceVariant!) : null,
      ),
    );

    final fallbackDetails = NotificationDetails(
      android: details.android,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: soundEnabled,
        presentBadge: false,
      ),
    );

    await _zonedScheduleWithIosFallback(
      id: 999001,
      title: 'GoToBed test',
      body: 'This is a test notification to confirm Android delivery.',
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      fallbackNotificationDetails: fallbackDetails,
      androidScheduleMode: await _safeScheduleMode(preferExact: true),
      payload: _payloadFor('test', 'manual'),
    );
  }

  Future<void> _createChannels() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _gentleDefaultChannelId,
        'Gentle reminders',
        description: 'Calm reminders before bedtime.',
        importance: Importance.defaultImportance,
      ),
    );

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _strongDefaultChannelId,
        'Bedtime reminders',
        description: 'Stronger nudges when bedtime arrives.',
        importance: Importance.high,
      ),
    );

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _testDefaultChannelId,
        'Test reminder',
        description: 'Manual test reminder with sound.',
        importance: Importance.max,
        playSound: true,
      ),
    );

    for (var i = 0; i < _softVoiceSoundResources.length; i++) {
      final variant = i + 1;
      final soundName = _softVoiceSoundResources[i];

      await androidImplementation?.createNotificationChannel(
        AndroidNotificationChannel(
          _voiceChannelId(strong: false, test: false, variant: variant),
          'Gentle reminders (voice $variant)',
          description: 'Calm reminders before bedtime with soft voice $variant.',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
      );

      await androidImplementation?.createNotificationChannel(
        AndroidNotificationChannel(
          _voiceChannelId(strong: true, test: false, variant: variant),
          'Bedtime reminders (voice $variant)',
          description:
              'Stronger nudges when bedtime arrives with soft voice $variant.',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
      );

      await androidImplementation?.createNotificationChannel(
        AndroidNotificationChannel(
          _voiceChannelId(strong: true, test: true, variant: variant),
          'Test reminder (voice $variant)',
          description: 'Manual test reminder with soft voice $variant.',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required bool strong,
    required bool soundEnabled,
    required ReminderSoundProfile soundProfile,
    required String payload,
  }) async {
    final voiceVariantIndex =
      soundEnabled && soundProfile == ReminderSoundProfile.softVoice
      ? _voiceVariantForSchedule()
      : null;
    final voiceVariant =
      voiceVariantIndex == null ? null : voiceVariantIndex + 1;

    final channelId = _channelIdFor(
      strong: strong,
      soundEnabled: soundEnabled,
      soundProfile: soundProfile,
      voiceVariant: voiceVariant,
    );

    final voiceSoundEnabled =
        soundEnabled && soundProfile == ReminderSoundProfile.softVoice;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        strong ? 'Bedtime reminders' : 'Gentle reminders',
        channelDescription: strong
            ? 'Stronger nudges when bedtime arrives.'
            : 'Calm reminders before bedtime.',
        importance: strong ? Importance.high : Importance.defaultImportance,
        priority: strong ? Priority.high : Priority.defaultPriority,
        playSound: soundEnabled,
        enableVibration: soundEnabled,
        sound: voiceSoundEnabled
            ? RawResourceAndroidNotificationSound(
                _softVoiceSoundResources[voiceVariantIndex!],
              )
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: soundEnabled,
        presentBadge: false,
        sound: voiceSoundEnabled ? _iosSoundFileName(voiceVariant!) : null,
      ),
    );

    final fallbackDetails = NotificationDetails(
      android: details.android,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: soundEnabled,
        presentBadge: false,
      ),
    );

    await _zonedScheduleWithIosFallback(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      fallbackNotificationDetails: fallbackDetails,
      androidScheduleMode: await _safeScheduleMode(preferExact: false),
      payload: payload,
    );
  }

  Future<void> _zonedScheduleWithIosFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required NotificationDetails fallbackNotificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        payload: payload,
      );
    } on PlatformException {
      if (kIsWeb || !Platform.isIOS) {
        rethrow;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: fallbackNotificationDetails,
        androidScheduleMode: androidScheduleMode,
        payload: payload,
      );
    }
  }

  Future<AndroidScheduleMode> _safeScheduleMode({
    required bool preferExact,
  }) async {
    if (!preferExact) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    try {
      final canScheduleExact =
          await androidImplementation?.canScheduleExactNotifications();
      if (canScheduleExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } on PlatformException {
      // Fall through to inexact mode for devices where exact alarms are denied.
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  String _channelIdFor({
    required bool strong,
    required bool soundEnabled,
    required ReminderSoundProfile soundProfile,
    required int? voiceVariant,
  }) {
    if (!soundEnabled || soundProfile == ReminderSoundProfile.system) {
      return strong ? _strongDefaultChannelId : _gentleDefaultChannelId;
    }

    return _voiceChannelId(
      strong: strong,
      test: false,
      variant: (voiceVariant ?? 0) + 1,
    );
  }

  int _voiceVariantForSchedule() {
    return _random.nextInt(_softVoiceSoundResources.length);
  }

  String _iosSoundFileName(int variant) {
    return 'sleep_$variant.wav';
  }

  String _voiceChannelId({
    required bool strong,
    required bool test,
    required int variant,
  }) {
    final stage = test
        ? 'test'
        : (strong ? 'strong' : 'gentle');
    return 'sleep_nudger_${stage}_voice_$variant';
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
