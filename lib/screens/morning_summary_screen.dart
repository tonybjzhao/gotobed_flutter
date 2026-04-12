import 'package:flutter/material.dart';

import '../models/morning_summary_copy.dart';
import '../models/nightly_result.dart';
import '../models/streak_feedback.dart';
import '../widgets/primary_button.dart';

class MorningSummaryScreen extends StatelessWidget {
  const MorningSummaryScreen({
    super.key,
    required this.result,
    required this.copy,
    required this.streakFeedback,
    required this.onContinue,
  });

  final NightlyResult result;
  final MorningSummaryCopy copy;
  final StreakFeedback streakFeedback;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(),
              Text(
                copy.title,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                copy.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF211B2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Current streak',
                      style: TextStyle(color: Color(0xFFCBB9A6)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      streakFeedback.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFFF2B36F),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      streakFeedback.countLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      streakFeedback.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFCBB9A6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(label: 'Continue', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}
