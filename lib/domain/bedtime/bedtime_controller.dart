import '../../models/nightly_result.dart';
import 'bedtime_copy.dart';
import 'bedtime_copy_engine.dart';
import 'bedtime_state.dart';

class BedtimeController {
  BedtimeController({
    required this.now,
    required this.night,
    required this.leadTime,
    required this.streak,
  }) : _copyEngine = BedtimeCopyEngine(seed: _seedFromNightId(night.nightId));

  final DateTime now;
  final NightlyResult night;
  final Duration leadTime;
  final int streak;
  final BedtimeCopyEngine _copyEngine;

  late final TonightState state = computeTonightState(
    TonightStateInput(
      now: now,
      bedtime: night.bedtime,
      leadTime: leadTime,
      confirmedForTonight: night.confirmedAt != null,
      missedForTonight: night.isResolved && night.wasSuccessful != true,
    ),
  );

  late final TonightCopy tonightCopy = _copyEngine.buildTonightCopy(
    state: state,
  );

  late final StreakDisplayCopy streakCopy = _copyEngine.buildStreakCopy(streak);

  static int _seedFromNightId(String nightId) {
    return int.tryParse(nightId.replaceAll('-', '')) ?? 0;
  }
}
