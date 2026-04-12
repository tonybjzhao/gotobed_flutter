class TonightCopy {
  const TonightCopy({
    required this.title,
    required this.subtitle,
    required this.nextReminderLabel,
    required this.tonightPlan,
    required this.cta,
    required this.ctaEnabled,
  });

  final String title;
  final String subtitle;
  final String nextReminderLabel;
  final String tonightPlan;
  final String cta;
  final bool ctaEnabled;
}

class StreakDisplayCopy {
  const StreakDisplayCopy({
    required this.title,
    required this.countLabel,
    required this.subtitle,
  });

  final String title;
  final String countLabel;
  final String subtitle;
}
