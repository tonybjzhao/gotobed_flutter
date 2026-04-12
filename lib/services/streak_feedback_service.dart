import '../models/streak_feedback.dart';

class StreakFeedbackService {
  const StreakFeedbackService();

  StreakFeedback resolve(int streak) {
    if (streak <= 0) {
      return const StreakFeedback(
        title: 'Start tonight',
        countLabel: '0 nights',
        subtitle: 'A small reset is still progress.',
      );
    }
    if (streak == 1) {
      return const StreakFeedback(
        title: 'Nice start',
        countLabel: '1 night',
        subtitle: 'One night is enough to begin.',
      );
    }
    if (streak <= 3) {
      return StreakFeedback(
        title: 'You are building this',
        countLabel: '$streak nights',
        subtitle: 'A small rhythm is forming.',
      );
    }
    if (streak <= 6) {
      return StreakFeedback(
        title: 'You are finding your pace',
        countLabel: '$streak nights',
        subtitle: 'This is starting to feel real.',
      );
    }

    return StreakFeedback(
      title: 'This is your rhythm',
      countLabel: '$streak nights',
      subtitle: 'You are becoming someone who rests.',
    );
  }
}
