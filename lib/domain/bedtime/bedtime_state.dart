enum TonightState {
  upcoming,
  gentleWindow,
  bedtimeWindow,
  doneForTonight,
  missed,
}

class TonightStateInput {
  const TonightStateInput({
    required this.now,
    required this.bedtime,
    required this.leadTime,
    required this.confirmedForTonight,
    required this.missedForTonight,
  });

  final DateTime now;
  final DateTime bedtime;
  final Duration leadTime;
  final bool confirmedForTonight;
  final bool missedForTonight;
}

TonightState computeTonightState(TonightStateInput input) {
  if (input.confirmedForTonight) {
    return TonightState.doneForTonight;
  }

  if (input.missedForTonight) {
    return TonightState.missed;
  }

  final gentleStart = input.bedtime.subtract(input.leadTime);
  final missedThreshold = input.bedtime.add(const Duration(hours: 2));

  if (input.now.isBefore(gentleStart)) {
    return TonightState.upcoming;
  }

  if (input.now.isBefore(input.bedtime)) {
    return TonightState.gentleWindow;
  }

  if (input.now.isBefore(missedThreshold)) {
    return TonightState.bedtimeWindow;
  }

  return TonightState.missed;
}
