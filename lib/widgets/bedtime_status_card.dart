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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final useVerticalMetrics = constraints.maxWidth < 380;
        final cardPadding = constraints.maxWidth < 360 ? 18.0 : 20.0;
        final Widget metricsSection = useVerticalMetrics
            ? Column(
                children: <Widget>[
                  _Metric(
                    label: 'Next reminder',
                    value: nextReminderLabel,
                    emphasized: true,
                  ),
                  const SizedBox(height: 12),
                  _StreakMetric(feedback: streakFeedback),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _Metric(
                      label: 'Next reminder',
                      value: nextReminderLabel,
                      emphasized: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _StreakMetric(feedback: streakFeedback)),
                ],
              );

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
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bedtimeLabel,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                metricsSection,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return _MetricShell(
      backgroundColor: emphasized
          ? const Color(0xFF332B3E)
          : const Color(0xFF2B2435),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
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
    return _MetricShell(
      backgroundColor: const Color(0x1AF2B36F),
      border: Border.all(color: const Color(0x33F2B36F)),
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
              height: 1.2,
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

class _MetricShell extends StatelessWidget {
  const _MetricShell({
    required this.child,
    this.backgroundColor = const Color(0xFF2B2435),
    this.border,
  });

  final Widget child;
  final Color backgroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
