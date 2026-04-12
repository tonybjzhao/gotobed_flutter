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
    reflection: 'You kept your word to yourself last night.',
    shareText: 'I went to bed on time last night with Sleep Nudger.',
  ),
  MorningSummaryCopy(
    title: 'You went to bed on time.',
    subtitle: 'A calmer night starts to become a pattern.',
    reflection: 'A good stop last night can make the next one easier.',
    shareText: 'Another on-time night in the books with Sleep Nudger.',
  ),
  MorningSummaryCopy(
    title: 'That was a good stop.',
    subtitle: 'Keep the rhythm going again tonight.',
    reflection: 'That kind of night adds up faster than it seems.',
    shareText: 'I kept the late-night scrolling shorter last night.',
  ),
];

const List<MorningSummaryCopy> _failureCopies = <MorningSummaryCopy>[
  MorningSummaryCopy(
    title: 'It happens.',
    subtitle: 'No guilt. Begin again tonight.',
    reflection: 'Coming back tonight still counts as progress.',
    shareText: 'Resetting tonight.\nOne late night does not erase the journey.',
  ),
  MorningSummaryCopy(
    title: 'Last night ran late.',
    subtitle: 'One late night does not undo your progress.',
    reflection: 'You are still building this, even on the uneven nights.',
    shareText: 'Last night ran late.\nTonight is a fresh start.',
  ),
  MorningSummaryCopy(
    title: 'A reset is still progress.',
    subtitle: 'Tonight is a fresh start.',
    reflection: 'A softer restart is better than giving up on the rhythm.',
    shareText: 'Starting again tonight.\nThat still counts.',
  ),
];
