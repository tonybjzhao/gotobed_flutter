import 'package:flutter/material.dart';

import '../models/streak_feedback.dart';

class BedtimeStatusCard extends StatelessWidget {
  const BedtimeStatusCard({
    super.key,
    required this.bedtimeLabel,
    required this.nextReminderLabel,
    required this.streakFeedback,
  });

  final String bedtimeLabel;
  final String nextReminderLabel;
  final StreakFeedback streakFeedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tonight’s bedtime',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: const Color(0xFFCBB9A6)),
            ),
            const SizedBox(height: 6),
            Text(
              bedtimeLabel,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Metric(
                    label: 'Next reminder',
                    value: nextReminderLabel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _StreakMetric(feedback: streakFeedback)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2435),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFFCBB9A6)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({required this.feedback});

  final StreakFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2435),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Current streak',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFFCBB9A6)),
          ),
          const SizedBox(height: 8),
          Text(
            feedback.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF2B36F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feedback.countLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFCBB9A6)),
          ),
        ],
      ),
    );
  }
}
