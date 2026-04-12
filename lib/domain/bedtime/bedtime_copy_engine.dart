import 'dart:math';

import 'bedtime_copy.dart';
import 'bedtime_state.dart';

class BedtimeCopyEngine {
  const BedtimeCopyEngine({required this.seed});

  final int seed;

  Random get _random => Random(seed);

  T _pick<T>(List<T> options) => options[_random.nextInt(options.length)];

  TonightCopy buildTonightCopy({required TonightState state}) {
    switch (state) {
      case TonightState.upcoming:
        return TonightCopy(
          title: _pick(const <String>[
            'Let’s slow down a bit.',
            'Tonight can be lighter.',
            'Ease into the evening.',
          ]),
          subtitle: _pick(const <String>[
            'Bedtime is getting closer.',
            'A calmer night starts with a small pause.',
            'You do not need to finish everything tonight.',
          ]),
          nextReminderLabel: 'Reminder coming later tonight',
          tonightPlan:
              'We will start softly before bedtime, then check in again if you are still up.',
          cta: "I’m going to bed",
          ctaEnabled: true,
        );
      case TonightState.gentleWindow:
        return TonightCopy(
          title: _pick(const <String>[
            'Hey… still here?',
            'It’s getting late.',
            'A small pause might help.',
          ]),
          subtitle: _pick(const <String>[
            'No pressure. Just a nudge toward rest.',
            'You can wrap up slowly from here.',
            'Tonight is enough.',
          ]),
          nextReminderLabel: 'Gentle reminder window',
          tonightPlan:
              'A gentle reminder is active now. If you stay up longer, the next nudge will be clearer.',
          cta: "I’m going to bed",
          ctaEnabled: true,
        );
      case TonightState.bedtimeWindow:
        return TonightCopy(
          title: _pick(const <String>[
            'Wind-down time.',
            'It may be time to stop scrolling.',
            'Your night can still reset here.',
          ]),
          subtitle: _pick(const <String>[
            'This is your bedtime nudge.',
            'You can still call it here and protect tomorrow.',
            'Just tonight is enough.',
          ]),
          nextReminderLabel: 'Bedtime reminder active',
          tonightPlan:
              'This is the firmer bedtime nudge. If you are ready, mark tonight as done and we will leave you in peace.',
          cta: "I’m going to bed",
          ctaEnabled: true,
        );
      case TonightState.doneForTonight:
        return const TonightCopy(
          title: 'Wind-down time.',
          subtitle: 'A calm night starts now.',
          nextReminderLabel:
              'You\'re on track tonight.\nWe\'ll be here if you need a nudge.',
          tonightPlan:
              'Let\'s wind down tonight.\nNo pressure. Just a little earlier.',
          cta: 'I\'m ready for tonight',
          ctaEnabled: false,
        );
      case TonightState.missed:
        return const TonightCopy(
          title: 'Last night ran late.',
          subtitle: 'One late night does not undo your progress.',
          nextReminderLabel: 'Tonight is a fresh start',
          tonightPlan:
              'Take the reset gently. A small reset is still progress.',
          cta: 'Continue',
          ctaEnabled: true,
        );
    }
  }

  StreakDisplayCopy buildStreakCopy(int streak) {
    if (streak <= 0) {
      return const StreakDisplayCopy(
        title: 'Start your first calm night',
        countLabel: '0 nights',
        subtitle: 'Just tonight is enough.',
      );
    }
    if (streak == 1) {
      return const StreakDisplayCopy(
        title: 'Nice start',
        countLabel: '1 night',
        subtitle: 'One calm night counts.',
      );
    }
    if (streak <= 3) {
      return StreakDisplayCopy(
        title: 'You’re building momentum',
        countLabel: '$streak nights',
        subtitle: 'A few better nights can shift the week.',
      );
    }
    if (streak <= 6) {
      return StreakDisplayCopy(
        title: 'A steady rhythm',
        countLabel: '$streak nights',
        subtitle: 'This is starting to feel like your pace.',
      );
    }
    return StreakDisplayCopy(
      title: 'This is becoming yours',
      countLabel: '$streak nights',
      subtitle: 'You are building a calmer pattern that fits you.',
    );
  }
}
