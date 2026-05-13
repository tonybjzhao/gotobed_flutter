import 'package:flutter/material.dart';

import '../models/streak_feedback.dart';

class BedtimeStatusCard extends StatelessWidget {
  const BedtimeStatusCard({
    super.key,
    required this.bedtimeLabel,
    required this.nextReminderLabel,
    required this.streakFeedback,
    this.compact = false,
  });

  final String bedtimeLabel;
  final String nextReminderLabel;
  final StreakFeedback streakFeedback;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final cardPadding = compact
            ? (constraints.maxWidth < 360 ? 16.0 : 18.0)
            : (constraints.maxWidth < 360 ? 18.0 : 22.0);

        return Card(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tonight’s bedtime',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFCBB9A6),
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  bedtimeLabel,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                ),
                SizedBox(height: compact ? 12 : 16),
                Divider(color: const Color(0xFFCBB9A6).withValues(alpha: 0.13)),
                SizedBox(height: compact ? 8 : 10),
                _DetailRow(
                  label: 'Next reminder',
                  value: nextReminderLabel,
                  compact: compact,
                ),
                SizedBox(height: compact ? 10 : 12),
                _DetailRow(
                  label: 'Current streak',
                  value: streakFeedback.countLabel,
                  subtitle: streakFeedback.subtitle,
                  accentValue: true,
                  compact: compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.subtitle,
    this.accentValue = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final bool accentValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFCBB9A6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: accentValue
                      ? const Color(0xFFF2B36F)
                      : const Color(0xFFF9F1E7),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                SizedBox(height: compact ? 2 : 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFCBB9A6),
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
