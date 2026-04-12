import 'dart:math';

import '../models/morning_summary_copy.dart';

class MorningSummaryCopyService {
  MorningSummaryCopyService({Random? random}) : _random = random ?? Random();

  final Random _random;

  MorningSummaryCopy selectCopy({required bool success}) {
    final pool = success ? _successCopies : _failureCopies;
    return pool[_random.nextInt(pool.length)];
  }
}

const List<MorningSummaryCopy> _successCopies = <MorningSummaryCopy>[
  MorningSummaryCopy(
    title: 'You did it.',
    subtitle: 'That felt different, didn’t it?',
  ),
  MorningSummaryCopy(
    title: 'You went to bed on time.',
    subtitle: 'A calmer night starts to become a pattern.',
  ),
  MorningSummaryCopy(
    title: 'That was a good stop.',
    subtitle: 'Keep the rhythm going again tonight.',
  ),
];

const List<MorningSummaryCopy> _failureCopies = <MorningSummaryCopy>[
  MorningSummaryCopy(
    title: 'It happens.',
    subtitle: 'No guilt. Try again tonight.',
  ),
  MorningSummaryCopy(
    title: 'Last night ran late.',
    subtitle: 'One late night does not undo your progress.',
  ),
  MorningSummaryCopy(
    title: 'A reset is still progress.',
    subtitle: 'Tonight is a fresh start.',
  ),
];
