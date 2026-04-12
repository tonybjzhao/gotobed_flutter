import 'package:flutter/material.dart';

import '../domain/bedtime/bedtime_controller.dart';
import '../models/app_settings.dart';
import '../models/nightly_result.dart';
import '../models/streak_feedback.dart';
import '../widgets/bedtime_status_card.dart';
import '../widgets/info_card.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.currentNight,
    required this.streak,
    required this.isReminderActive,
    required this.onConfirmBedtime,
    required this.onSnooze,
    required this.onOpenSettings,
  });

  final AppSettings settings;
  final NightlyResult currentNight;
  final int streak;
  final bool isReminderActive;
  final Future<void> Function() onConfirmBedtime;
  final Future<void> Function() onSnooze;
  final VoidCallback onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BedtimeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentNight.nightId != widget.currentNight.nightId ||
        oldWidget.currentNight.confirmedAtIso !=
            widget.currentNight.confirmedAtIso ||
        oldWidget.currentNight.resolvedAtIso !=
            widget.currentNight.resolvedAtIso ||
        oldWidget.streak != widget.streak ||
        oldWidget.settings.reminderLeadMinutes !=
            widget.settings.reminderLeadMinutes) {
      _controller = _buildController();
    }
  }

  BedtimeController _buildController() {
    return BedtimeController(
      now: DateTime.now(),
      night: widget.currentNight,
      leadTime: Duration(minutes: widget.settings.reminderLeadMinutes),
      streak: widget.streak,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextReminderText = _nextReminderLabel(context);
    final bedtimeText = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(widget.settings.bedtime);
    final copy = _controller.tonightCopy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tonight'),
        actions: <Widget>[
          TextButton(
            onPressed: widget.onOpenSettings,
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: _fadeSlideTransition,
              child: Text(
                copy.title,
                key: ValueKey<String>(copy.title),
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: _fadeSlideTransition,
              child: Text(
                copy.subtitle,
                key: ValueKey<String>(copy.subtitle),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            BedtimeStatusCard(
              bedtimeLabel: bedtimeText,
              nextReminderLabel: nextReminderText,
              streakFeedback: _asLegacyStreakFeedback(),
            ),
            const SizedBox(height: 16),
            InfoCard(title: 'Tonight’s plan', subtitle: copy.tonightPlan),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: _fadeSlideTransition,
              child: PrimaryButton(
                key: ValueKey<String>(copy.cta),
                label: copy.cta,
                onPressed: copy.ctaEnabled ? widget.onConfirmBedtime : null,
              ),
            ),
            if (widget.isReminderActive) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.currentNight.snoozeCount >= 3
                    ? null
                    : widget.onSnooze,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: Color(0xFF5D516A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  widget.currentNight.snoozeCount >= 3
                      ? 'Snooze limit reached'
                      : 'Snooze 10 min',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _nextReminderLabel(BuildContext context) {
    if (widget.currentNight.confirmedAt != null) {
      return _controller.tonightCopy.nextReminderLabel;
    }
    if (widget.isReminderActive) {
      return _controller.tonightCopy.nextReminderLabel;
    }

    final localizations = MaterialLocalizations.of(context);
    final time = TimeOfDay.fromDateTime(widget.currentNight.nextReminderAt);
    return localizations.formatTimeOfDay(time);
  }

  Widget _fadeSlideTransition(Widget child, Animation<double> animation) {
    final position = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: position, child: child),
    );
  }

  StreakFeedback _asLegacyStreakFeedback() {
    return StreakFeedback(
      title: _controller.streakCopy.title,
      countLabel: _controller.streakCopy.countLabel,
      subtitle: _controller.streakCopy.subtitle,
    );
  }
}
