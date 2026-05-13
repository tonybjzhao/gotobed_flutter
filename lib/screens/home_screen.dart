import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/bedtime/bedtime_controller.dart';
import '../domain/bedtime/bedtime_state.dart';
import '../models/app_settings.dart';
import '../models/nightly_result.dart';
import '../models/streak_feedback.dart';
import '../widgets/bedtime_status_card.dart';
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
    final media = MediaQuery.of(context);
    final viewportHeight =
        media.size.height - media.padding.vertical - kToolbarHeight;
    final compactLayout =
        viewportHeight < 820 || media.textScaler.scale(1) > 1.05;
    final nextReminderText = _nextReminderLabel(context);
    final bedtimeText = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(widget.settings.bedtime);
    final copy = _controller.tonightCopy;
    final heroCopy = _heroCopyForNow(
      now: DateTime.now(),
      state: _controller.state,
      fallbackTitle: copy.title,
      fallbackSubtitle: copy.subtitle,
    );
    final ritualMode =
        _isConfirmingBedtime || widget.currentNight.confirmedAt != null;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: compactLayout ? 52 : 56,
        title: const Text('Tonight'),
        titleTextStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: const Color(0xFFF9F1E7),
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
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
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _NightAtmosphere()),
              ListView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  compactLayout ? 6 : 12,
                  24,
                  compactLayout ? 22 : 32,
                ),
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: _fadeSlideTransition,
                    child: Text(
                      heroCopy.title,
                      key: ValueKey<String>(heroCopy.title),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: compactLayout ? 34 : 38,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                  SizedBox(height: compactLayout ? 14 : 20),
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
                            compact: compactLayout,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: compactLayout ? 16 : 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: _fadeSlideTransition,
                    child: PrimaryButton(
                      key: ValueKey<String>(copy.cta),
                      label: _isConfirmingBedtime ? 'Settling in...' : copy.cta,
                      onPressed: copy.ctaEnabled ? _handlePrimaryAction : null,
                      dense: compactLayout,
                    ),
                  ),
                  SizedBox(height: compactLayout ? 10 : 14),
                  Text(
                    'Tomorrow starts tonight.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFCBB9A6).withValues(alpha: 0.48),
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: compactLayout ? 2 : 4),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: <Widget>[
                        TextButton(
                          onPressed: widget.onOpenSettings,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(
                              0xFFCBB9A6,
                            ).withValues(alpha: 0.7),
                            visualDensity: VisualDensity.compact,
                            textStyle: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 13),
                          ),
                          child: const Text('Settings'),
                        ),
                        Text(
                          '·',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF6E6478)),
                        ),
                        TextButton(
                          onPressed: () => _showAboutSheet(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(
                              0xFFCBB9A6,
                            ).withValues(alpha: 0.7),
                            visualDensity: VisualDensity.compact,
                            textStyle: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 13),
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
            ],
          ),
        ),
      ),
    );
  }

  String _nextReminderLabel(BuildContext context) {
    if (widget.currentNight.confirmedAt != null) {
      return 'On track tonight';
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
        final bottomPadding = MediaQuery.paddingOf(context).bottom;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 28 + bottomPadding),
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
                  'Tonight is home by design. Settings and About are quiet side paths, so the app always brings you back to winding down for the night.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFF2B36F),
                    height: 1.45,
                  ),
                ),
              ],
            ),
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

  _HeroCopy _heroCopyForNow({
    required DateTime now,
    required TonightState state,
    required String fallbackTitle,
    required String fallbackSubtitle,
  }) {
    if (state == TonightState.missed) {
      return _HeroCopy(title: fallbackTitle, subtitle: fallbackSubtitle);
    }

    if (now.hour < 21) {
      return const _HeroCopy(title: 'A calm night starts now.', subtitle: '');
    }

    if (now.hour < 23) {
      return const _HeroCopy(title: 'It’s getting late.', subtitle: '');
    }

    return const _HeroCopy(title: 'Still awake?', subtitle: '');
  }
}

class _HeroCopy {
  const _HeroCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _NightAtmosphere extends StatelessWidget {
  const _NightAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.15, 1.06),
            radius: 0.88,
            colors: <Color>[
              const Color(0xFFF2B36F).withValues(alpha: 0.11),
              const Color(0xFF8E7DBE).withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.38, 1],
          ),
        ),
        child: const Stack(
          children: <Widget>[
            _StarDot(left: 0.16, bottom: 0.19, size: 2.2, opacity: 0.20),
            _StarDot(left: 0.33, bottom: 0.28, size: 1.6, opacity: 0.16),
            _StarDot(left: 0.68, bottom: 0.22, size: 1.8, opacity: 0.18),
            _StarDot(left: 0.82, bottom: 0.34, size: 2.4, opacity: 0.14),
            _StarDot(left: 0.52, bottom: 0.13, size: 1.4, opacity: 0.14),
          ],
        ),
      ),
    );
  }
}

class _StarDot extends StatelessWidget {
  const _StarDot({
    required this.left,
    required this.bottom,
    required this.size,
    required this.opacity,
  });

  final double left;
  final double bottom;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.sizeOf(context).width * left,
      bottom: MediaQuery.sizeOf(context).height * bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9F1E7).withValues(alpha: opacity),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFF2B36F).withValues(alpha: opacity * 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
