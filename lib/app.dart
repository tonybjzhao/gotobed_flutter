import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'models/bedtime_message.dart';
import 'models/morning_summary_copy.dart';
import 'models/nightly_result.dart';
import 'screens/home_screen.dart';
import 'screens/morning_summary_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'services/bedtime_message_engine.dart';
import 'services/bedtime_logic_service.dart';
import 'services/morning_summary_copy_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/streak_feedback_service.dart';
import 'services/streak_service.dart';

class SleepNudgerApp extends StatelessWidget {
  const SleepNudgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF14111B);
    const surface = Color(0xFF211B2A);
    const accent = Color(0xFFF2B36F);
    const text = Color(0xFFF9F1E7);
    const muted = Color(0xFFCBB9A6);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ).copyWith(
          surface: surface,
          primary: accent,
          secondary: const Color(0xFF8E7DBE),
          onPrimary: const Color(0xFF2B1802),
          onSurface: text,
        );

    return MaterialApp(
      title: 'Sleep Nudger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: text,
          displayColor: text,
        ),
        cardTheme: CardThemeData(
          color: surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: text,
          elevation: 0,
        ),
        dividerColor: muted.withValues(alpha: 0.18),
      ),
      home: const SleepNudgerRoot(),
    );
  }
}

class SleepNudgerRoot extends StatefulWidget {
  const SleepNudgerRoot({super.key});

  @override
  State<SleepNudgerRoot> createState() => _SleepNudgerRootState();
}

class _SleepNudgerRootState extends State<SleepNudgerRoot> {
  final StorageService _storageService = StorageService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final StreakService _streakService = StreakService.instance;
  final BedtimeLogicService _logicService = BedtimeLogicService.instance;
  final BedtimeMessageEngine _bedtimeMessageEngine = BedtimeMessageEngine();
  final MorningSummaryCopyService _morningSummaryCopyService =
      MorningSummaryCopyService();
  final StreakFeedbackService _streakFeedbackService =
      const StreakFeedbackService();

  bool _isLoading = true;
  bool _showSettings = false;
  AppSettings? _settings;
  NightlyResult? _currentNight;
  NightlyResult? _morningSummary;
  int _streak = 0;
  BedtimeMessage? _homeMessage;
  MorningSummaryCopy? _morningSummaryCopy;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _notificationService.initialize();
    await _refreshState();
  }

  Future<void> _refreshState() async {
    setState(() {
      _isLoading = true;
    });

    final settings = await _storageService.loadSettings();
    if (settings == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _settings = null;
        _currentNight = null;
        _morningSummary = null;
        _streak = 0;
        _homeMessage = null;
        _morningSummaryCopy = null;
        _showSettings = false;
        _isLoading = false;
      });
      return;
    }

    final now = DateTime.now();
    final interactionDate = _logicService.interactionNightDate(now);
    final interactionNight = await _ensureNightForDate(
      settings: settings,
      nightDate: interactionDate,
    );

    final summary = await _streakService.resolveMorningSummaryIfNeeded(
      settings: settings,
      now: now,
    );

    final upcomingDate = _logicService.upcomingNotificationNightDate(
      now,
      settings,
    );
    final upcomingNight = await _ensureNightForDate(
      settings: settings,
      nightDate: upcomingDate,
    );

    await _notificationService.scheduleNightPlan(
      settings: settings,
      night: upcomingNight,
      now: now,
    );

    final streak = await _storageService.loadCurrentStreak();
    final homeMessage = _bedtimeMessageEngine.selectMessage(
      now: now,
      bedtimeToday: interactionNight.bedtime,
    );
    final morningSummaryCopy = summary == null
        ? null
        : _morningSummaryCopyService.selectCopy(
            success: summary.wasSuccessful == true,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _currentNight = interactionNight;
      _morningSummary = summary;
      _streak = streak;
      _homeMessage = homeMessage;
      _morningSummaryCopy = morningSummaryCopy;
      _isLoading = false;
    });
  }

  Future<NightlyResult> _ensureNightForDate({
    required AppSettings settings,
    required DateTime nightDate,
  }) async {
    final nightId = _logicService.nightIdFromDate(nightDate);
    final storedNight = await _storageService.loadNightlyResult(nightId);
    final syncedNight = _logicService.syncNightWithSettings(
      existing: storedNight,
      settings: settings,
      nightDate: nightDate,
      now: DateTime.now(),
    );

    await _storageService.saveNightlyResult(syncedNight);
    return syncedNight;
  }

  Future<void> _handleOnboardingSave(AppSettings settings) async {
    await _storageService.saveSettings(settings);
    await _notificationService.requestPermissions();
    await _refreshState();
  }

  Future<void> _handleSettingsSave(AppSettings settings) async {
    await _storageService.saveSettings(settings);
    if (!mounted) {
      return;
    }

    setState(() {
      _showSettings = false;
    });
    await _refreshState();
  }

  Future<void> _handleBedtimeConfirmation() async {
    final settings = _settings;
    final currentNight = _currentNight;
    if (settings == null ||
        currentNight == null ||
        currentNight.confirmedAt != null) {
      return;
    }

    final updatedNight = _logicService.markConfirmed(
      currentNight,
      DateTime.now(),
    );
    await _storageService.saveNightlyResult(updatedNight);
    await _notificationService.cancelNightNotifications(updatedNight.nightId);
    await _refreshState();
  }

  Future<void> _handleSnooze() async {
    final settings = _settings;
    final currentNight = _currentNight;
    if (settings == null || currentNight == null) {
      return;
    }

    final now = DateTime.now();
    if (!_logicService.canSnooze(currentNight, now)) {
      return;
    }

    final snoozedNight = _logicService.applySnooze(currentNight, now);
    await _storageService.saveNightlyResult(snoozedNight);
    await _notificationService.scheduleSnoozeReminder(
      settings: settings,
      night: snoozedNight,
      now: now,
    );
    await _refreshState();
  }

  Future<void> _handleMorningSummaryContinue() async {
    final summary = _morningSummary;
    if (summary == null) {
      return;
    }

    final updatedSummary = summary.copyWith(summaryShown: true);
    await _storageService.saveNightlyResult(updatedSummary);
    await _refreshState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final settings = _settings;
    if (settings == null) {
      return OnboardingScreen(
        initialSettings: AppSettings.defaults(),
        onSave: _handleOnboardingSave,
      );
    }

    if (_showSettings) {
      return SettingsScreen(
        settings: settings,
        onSave: _handleSettingsSave,
        onCancel: () {
          setState(() {
            _showSettings = false;
          });
        },
      );
    }

    final morningSummary = _morningSummary;
    if (morningSummary != null && !morningSummary.summaryShown) {
      return MorningSummaryScreen(
        result: morningSummary,
        copy:
            _morningSummaryCopy ??
            _morningSummaryCopyService.selectCopy(
              success: morningSummary.wasSuccessful == true,
            ),
        streakFeedback: _streakFeedbackService.resolve(_streak),
        onContinue: _handleMorningSummaryContinue,
      );
    }

    final currentNight = _currentNight;
    if (currentNight == null) {
      return const Scaffold(
        body: Center(child: Text('Unable to load tonight’s bedtime.')),
      );
    }

    return HomeScreen(
      settings: settings,
      currentNight: currentNight,
      sessionMessage:
          _homeMessage ??
          _bedtimeMessageEngine.selectMessage(
            now: DateTime.now(),
            bedtimeToday: currentNight.bedtime,
          ),
      streakFeedback: _streakFeedbackService.resolve(_streak),
      isReminderActive: _logicService.isReminderActive(
        currentNight,
        DateTime.now(),
      ),
      onConfirmBedtime: _handleBedtimeConfirmation,
      onSnooze: _handleSnooze,
      onOpenSettings: () {
        setState(() {
          _showSettings = true;
        });
      },
    );
  }
}
