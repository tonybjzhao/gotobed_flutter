import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final success = result.wasSuccessful == true;
    final shareTitle = success
        ? '${streakFeedback.countLabel} of going to bed on time'
        : 'Starting again tonight';

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
              const SizedBox(height: 12),
              Text(
                copy.reflection,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFF2B36F),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),
              _ShareCard(
                title: shareTitle,
                body: copy.shareText,
                onCopy: () => _copyShareText(context, copy.shareText),
              ),
              const Spacer(),
              PrimaryButton(label: 'Continue', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyShareText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress note copied')));
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.title,
    required this.body,
    required this.onCopy,
  });

  final String title;
  final String body;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18131F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33F2B36F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Shareable progress',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFFCBB9A6)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF4EEE8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFCBB9A6),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onCopy,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x55F2B36F)),
                foregroundColor: const Color(0xFFF2B36F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Copy progress note'),
            ),
          ),
        ],
      ),
    );
  }
}
