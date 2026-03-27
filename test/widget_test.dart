import 'package:flutter_test/flutter_test.dart';
import 'package:byebyemobile_flutter/models/app_settings.dart';
import 'package:byebyemobile_flutter/services/bedtime_logic_service.dart';

void main() {
  final logic = BedtimeLogicService.instance;

  test('resolves success only inside grace period', () {
    final settings = AppSettings.defaults();
    final night = logic.buildNight(
      settings: settings,
      nightDate: DateTime(2026, 3, 21),
    );

    final confirmed = logic.markConfirmed(night, DateTime(2026, 3, 21, 23, 15));
    final resolved = logic.resolveNight(
      confirmed,
      DateTime(2026, 3, 22, 6, 30),
    );

    expect(resolved.wasSuccessful, isTrue);
  });

  test('blocks snooze after three uses', () {
    final settings = AppSettings.defaults();
    var night = logic.buildNight(
      settings: settings,
      nightDate: DateTime(2026, 3, 21),
    );

    final start = DateTime(2026, 3, 21, 23, 0);
    for (var i = 0; i < 3; i++) {
      night = logic.applySnooze(night, start.add(Duration(minutes: i * 10)));
    }

    expect(logic.canSnooze(night, DateTime(2026, 3, 21, 23, 31)), isFalse);
  });
}
