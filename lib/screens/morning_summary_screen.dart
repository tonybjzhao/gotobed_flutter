import 'package:flutter/material.dart';

import '../models/nightly_result.dart';
import '../widgets/primary_button.dart';

class MorningSummaryScreen extends StatelessWidget {
  const MorningSummaryScreen({
    super.key,
    required this.result,
    required this.streak,
    required this.onContinue,
  });

  final NightlyResult result;
  final int streak;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final success = result.wasSuccessful == true;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(),
              Text(
                success
                    ? 'You went to bed on time 🎉'
                    : 'You stayed up late last night',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                success
                    ? 'Nice work. Keep the rhythm going tonight.'
                    : 'No guilt trip. Reset and try again tonight.',
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
                      '$streak night${streak == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFFF2B36F),
                            fontWeight: FontWeight.w700,
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
