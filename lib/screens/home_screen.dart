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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  compactLayout ? 6 : 12,
                  24,
                  compactLayout ? 34 : 46,
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
                            fontWeight: FontWeight.w700,
                            height: 1.12,
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
                      height: 1.45,
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
                  if (!widget.isReminderActive) ...<Widget>[
                    SizedBox(height: compactLayout ? 18 : 26),
                    _TonightReflection(
                      streak: widget.streak,
                      compact: compactLayout,
                    ),
                  ],
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
    final sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 240),
    );

    return showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.66),
      backgroundColor: const Color(0xFF211B2A),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      transitionAnimationController: sheetController,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        final bottomPadding = MediaQuery.paddingOf(context).bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 28,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8A7C9).withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'About GoToBed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'GoToBed helps you end the day a little earlier.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFCBB9A6),
                    height: 1.58,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Not through pressure, but through gentler evenings.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFF9F1E7),
                    height: 1.58,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'One quieter night can change tomorrow.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFCBB9A6).withValues(alpha: 0.82),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(sheetController.dispose);
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

class _TonightReflection extends StatelessWidget {
  const _TonightReflection({required this.streak, required this.compact});

  final int streak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reflection = streak > 0
        ? 'You have already begun. Keep tonight simple.'
        : 'One quiet choice is enough for tonight.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF211B2A).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCBB9A6).withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 18,
          compact ? 14 : 16,
          compact ? 16 : 18,
          compact ? 14 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tonight reflection',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFFCBB9A6).withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reflection,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF9F1E7).withValues(alpha: 0.78),
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              const Color(0xFFF2B36F).withValues(alpha: 0.075),
              const Color(0xFF8E7DBE).withValues(alpha: 0.055),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.38, 1],
          ),
        ),
        child: const Stack(
          children: <Widget>[
            _StarDot(left: 0.18, bottom: 0.20, size: 1.7, opacity: 0.12),
            _StarDot(left: 0.67, bottom: 0.23, size: 1.5, opacity: 0.11),
            _StarDot(left: 0.83, bottom: 0.35, size: 1.9, opacity: 0.10),
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
              blurRadius: 12,
              spreadRadius: 0.6,
            ),
          ],
        ),
      ),
    );
  }
}
