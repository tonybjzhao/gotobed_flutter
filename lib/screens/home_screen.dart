import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isConfirmingBedtime = false;

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

    if (widget.currentNight.confirmedAt != null && _isConfirmingBedtime) {
      _isConfirmingBedtime = false;
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
    final ritualMode =
        _isConfirmingBedtime || widget.currentNight.confirmedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tonight'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: widget.onOpenSettings,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Settings'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF2B36F),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          color: ritualMode ? const Color(0x0DFFFFFF) : Colors.transparent,
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
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
              AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                offset: ritualMode ? const Offset(0, 0.02) : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: ritualMode ? 0.94 : 1,
                  child: Column(
                    children: <Widget>[
                      BedtimeStatusCard(
                        bedtimeLabel: bedtimeText,
                        nextReminderLabel: nextReminderText,
                        streakFeedback: _asLegacyStreakFeedback(),
                      ),
                      const SizedBox(height: 16),
                      InfoCard(
                        title: 'Tonight’s plan',
                        subtitle: copy.tonightPlan,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _fadeSlideTransition,
                child: PrimaryButton(
                  key: ValueKey<String>(copy.cta),
                  label: _isConfirmingBedtime ? 'Settling in...' : copy.cta,
                  onPressed: copy.ctaEnabled ? _handlePrimaryAction : null,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: <Widget>[
                    TextButton(
                      onPressed: widget.onOpenSettings,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCBB9A6),
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      child: const Text('Settings'),
                    ),
                    Text(
                      '·',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6E6478),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAboutSheet(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCBB9A6),
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                      child: const Text('About'),
                    ),
                  ],
                ),
              ),
              if (widget.isReminderActive && !ritualMode) ...<Widget>[
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
      ),
    );
  }

  String _nextReminderLabel(BuildContext context) {
    if (widget.currentNight.confirmedAt != null) {
      return _controller.tonightCopy.nextReminderLabel;
    }

    final now = DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(widget.currentNight.nextReminderAt),
    );
    final whenLabel = _dayLabel(now, widget.currentNight.nextReminderAt);

    if (widget.isReminderActive) {
      return 'Active now · $whenLabel $time';
    }

    return '$whenLabel $time';
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

  Future<void> _handlePrimaryAction() async {
    if (_isConfirmingBedtime || !_controller.tonightCopy.ctaEnabled) {
      return;
    }

    await HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _isConfirmingBedtime = true;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 280));
    await widget.onConfirmBedtime();

    if (mounted && widget.currentNight.confirmedAt == null) {
      setState(() {
        _isConfirmingBedtime = false;
      });
    }
  }

  Future<void> _showAboutSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D516A),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'About GoToBed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'GoToBed is a gentle bedtime companion built to help late-night scrolling end a little earlier, without guilt.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Root screen by design: Tonight is home. Settings and a small About sheet are the soft exits.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFF2B36F),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  StreakFeedback _asLegacyStreakFeedback() {
    return StreakFeedback(
      title: _controller.streakCopy.title,
      countLabel: _controller.streakCopy.countLabel,
      subtitle: _controller.streakCopy.subtitle,
    );
  }

  String _dayLabel(DateTime now, DateTime target) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDay = DateTime(target.year, target.month, target.day);

    if (targetDay == today) {
      return 'Today ·';
    }
    if (targetDay == tomorrow) {
      return 'Tomorrow ·';
    }
    return '${target.month}/${target.day} ·';
  }
}
