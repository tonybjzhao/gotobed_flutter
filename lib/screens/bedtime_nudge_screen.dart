import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BedtimeNudgeScreen extends StatefulWidget {
  const BedtimeNudgeScreen({
    super.key,
    required this.onGoingToSleep,
    required this.onRemindLater,
  });

  final Future<void> Function() onGoingToSleep;
  final Future<void> Function() onRemindLater;

  @override
  State<BedtimeNudgeScreen> createState() => _BedtimeNudgeScreenState();
}

class _BedtimeNudgeScreenState extends State<BedtimeNudgeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  bool _isClosing = false;
  bool _isSnoozing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToSleep() async {
    if (_isClosing || _isSnoozing) {
      return;
    }

    await HapticFeedback.lightImpact();
    setState(() {
      _isClosing = true;
    });
    await widget.onGoingToSleep();
  }

  Future<void> _remindLater() async {
    if (_isClosing || _isSnoozing) {
      return;
    }

    await HapticFeedback.selectionClick();
    setState(() {
      _isSnoozing = true;
    });
    await widget.onRemindLater();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            children: <Widget>[
              const Spacer(),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final value = _pulse.value;
                  return Container(
                    width: 164 + value * 34,
                    height: 164 + value * 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF111018),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(
                            0xFFF2B36F,
                          ).withValues(alpha: 0.14 + value * 0.12),
                          blurRadius: 42 + value * 28,
                          spreadRadius: 8 + value * 14,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(
                          0xFFF2B36F,
                        ).withValues(alpha: 0.22 + value * 0.16),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: 0.86 + value * 0.08,
                      child: child,
                    ),
                  );
                },
                child: const Icon(
                  Icons.nightlight_round,
                  size: 74,
                  color: Color(0xFFF2B36F),
                ),
              ),
              const SizedBox(height: 52),
              Text(
                'It’s time to go to bed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.08,
                  color: const Color(0xFFF9F1E7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Put the phone down. You did enough today.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isClosing || _isSnoozing ? null : _goToSleep,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFFF2B36F),
                  foregroundColor: const Color(0xFF241406),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isClosing ? 'Good night...' : 'I’m going to sleep',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isClosing || _isSnoozing ? null : _remindLater,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFCBB9A6),
                  minimumSize: const Size.fromHeight(52),
                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(
                  _isSnoozing
                      ? 'Setting reminder...'
                      : 'Remind me in 10 minutes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
