import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/nightly_result.dart';
import '../widgets/bedtime_status_card.dart';
import '../widgets/info_card.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final nextReminderText = _nextReminderLabel(context);
    final bedtimeText = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(settings.bedtime);
    final bedtimeConfirmed = currentNight.confirmedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tonight'),
        actions: <Widget>[
          TextButton(onPressed: onOpenSettings, child: const Text('Edit')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: <Widget>[
            Text(
              'Wind-down time 🙂',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'A simple nudge to help you stop scrolling and head to bed.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFCBB9A6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            BedtimeStatusCard(
              bedtimeLabel: bedtimeText,
              nextReminderLabel: nextReminderText,
              streak: streak,
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Tonight’s tone',
              subtitle: settings.gentleReminderEnabled
                  ? 'Gentle reminder first, then a firmer bedtime nudge.'
                  : 'Direct bedtime reminder only.',
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: bedtimeConfirmed
                  ? 'Bedtime confirmed'
                  : 'I’m going to bed',
              onPressed: bedtimeConfirmed ? null : onConfirmBedtime,
            ),
            if (isReminderActive) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: currentNight.snoozeCount >= 3 ? null : onSnooze,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: Color(0xFF5D516A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  currentNight.snoozeCount >= 3
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
    if (currentNight.confirmedAt != null) {
      return 'Bedtime confirmed';
    }
    if (isReminderActive) {
      return 'Reminder active now';
    }

    final localizations = MaterialLocalizations.of(context);
    final time = TimeOfDay.fromDateTime(currentNight.nextReminderAt);
    return localizations.formatTimeOfDay(time);
  }
}
