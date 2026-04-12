import 'dart:math';

import '../models/bedtime_message.dart';
import '../models/bedtime_tone.dart';

class BedtimeMessageEngine {
  BedtimeMessageEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  BedtimeTone resolveTone({
    required DateTime now,
    required DateTime bedtimeToday,
  }) {
    final difference = bedtimeToday.difference(now).inMinutes;

    if (difference > 30) {
      return BedtimeTone.gentle;
    }
    if (difference >= 0) {
      return BedtimeTone.neutral;
    }
    return BedtimeTone.firm;
  }

  BedtimeMessage selectMessage({
    required DateTime now,
    required DateTime bedtimeToday,
  }) {
    final tone = resolveTone(now: now, bedtimeToday: bedtimeToday);
    return selectMessageForTone(tone);
  }

  BedtimeMessage selectMessageForTone(BedtimeTone tone) {
    final pool = _poolForTone(tone);
    return pool[_random.nextInt(pool.length)];
  }

  List<BedtimeMessage> _poolForTone(BedtimeTone tone) {
    switch (tone) {
      case BedtimeTone.gentle:
        return _gentleMessages;
      case BedtimeTone.neutral:
        return _neutralMessages;
      case BedtimeTone.firm:
        return _firmMessages;
    }
  }
}

const List<BedtimeMessage> _gentleMessages = <BedtimeMessage>[
  BedtimeMessage(
    tone: BedtimeTone.gentle,
    title: 'Wind-down time.',
    subtitle: 'A calm night starts now.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.gentle,
    title: 'Take it slow tonight.',
    subtitle: 'You do not need to finish everything before bed.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.gentle,
    title: 'A softer night starts here.',
    subtitle: 'Let the day get a little quieter.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.gentle,
    title: 'Ease into the evening.',
    subtitle: 'Bedtime is getting closer.',
  ),
];

const List<BedtimeMessage> _neutralMessages = <BedtimeMessage>[
  BedtimeMessage(
    tone: BedtimeTone.neutral,
    title: 'It is getting late.',
    subtitle: 'Maybe this is a good place to stop.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.neutral,
    title: 'Your bedtime is coming up.',
    subtitle: 'Tonight can still end well.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.neutral,
    title: 'A small stop now will help tomorrow.',
    subtitle: 'You can leave the rest for morning.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.neutral,
    title: 'This could be your last scroll.',
    subtitle: 'Put the phone down while it still feels easy.',
  ),
];

const List<BedtimeMessage> _firmMessages = <BedtimeMessage>[
  BedtimeMessage(
    tone: BedtimeTone.firm,
    title: 'Still scrolling?',
    subtitle: 'No guilt. You can still reset tonight.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.firm,
    title: 'It is past bedtime.',
    subtitle: 'The day is done. Let yourself rest.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.firm,
    title: 'You can stop here.',
    subtitle: 'Sleep will feel better than one more scroll.',
  ),
  BedtimeMessage(
    tone: BedtimeTone.firm,
    title: 'It is late, and that is okay.',
    subtitle: 'Be kind to yourself and head to bed now.',
  ),
];
