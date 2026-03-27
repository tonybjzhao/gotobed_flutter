import 'dart:convert';

class NightlyResult {
  const NightlyResult({
    required this.nightId,
    required this.bedtimeIso,
    required this.strongReminderIso,
    required this.graceDeadlineIso,
    required this.nextReminderAtIso,
    this.gentleReminderIso,
    this.confirmedAtIso,
    this.resolvedAtIso,
    this.wasSuccessful,
    this.snoozeCount = 0,
    this.summaryShown = false,
  });

  final String nightId;
  final String bedtimeIso;
  final String? gentleReminderIso;
  final String strongReminderIso;
  final String graceDeadlineIso;
  final String nextReminderAtIso;
  final String? confirmedAtIso;
  final String? resolvedAtIso;
  final bool? wasSuccessful;
  final int snoozeCount;
  final bool summaryShown;

  DateTime get bedtime => DateTime.parse(bedtimeIso);
  DateTime? get gentleReminderAt =>
      gentleReminderIso == null ? null : DateTime.parse(gentleReminderIso!);
  DateTime get strongReminderAt => DateTime.parse(strongReminderIso);
  DateTime get graceDeadline => DateTime.parse(graceDeadlineIso);
  DateTime get nextReminderAt => DateTime.parse(nextReminderAtIso);
  DateTime? get confirmedAt =>
      confirmedAtIso == null ? null : DateTime.parse(confirmedAtIso!);
  DateTime? get resolvedAt =>
      resolvedAtIso == null ? null : DateTime.parse(resolvedAtIso!);

  bool get isResolved => resolvedAtIso != null;

  NightlyResult copyWith({
    String? nightId,
    String? bedtimeIso,
    String? gentleReminderIso,
    bool clearGentleReminderIso = false,
    String? strongReminderIso,
    String? graceDeadlineIso,
    String? nextReminderAtIso,
    String? confirmedAtIso,
    bool clearConfirmedAtIso = false,
    String? resolvedAtIso,
    bool clearResolvedAtIso = false,
    bool? wasSuccessful,
    bool clearWasSuccessful = false,
    int? snoozeCount,
    bool? summaryShown,
  }) {
    return NightlyResult(
      nightId: nightId ?? this.nightId,
      bedtimeIso: bedtimeIso ?? this.bedtimeIso,
      gentleReminderIso: clearGentleReminderIso
          ? null
          : gentleReminderIso ?? this.gentleReminderIso,
      strongReminderIso: strongReminderIso ?? this.strongReminderIso,
      graceDeadlineIso: graceDeadlineIso ?? this.graceDeadlineIso,
      nextReminderAtIso: nextReminderAtIso ?? this.nextReminderAtIso,
      confirmedAtIso: clearConfirmedAtIso
          ? null
          : confirmedAtIso ?? this.confirmedAtIso,
      resolvedAtIso: clearResolvedAtIso
          ? null
          : resolvedAtIso ?? this.resolvedAtIso,
      wasSuccessful: clearWasSuccessful
          ? null
          : wasSuccessful ?? this.wasSuccessful,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      summaryShown: summaryShown ?? this.summaryShown,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nightId': nightId,
      'bedtimeIso': bedtimeIso,
      'gentleReminderIso': gentleReminderIso,
      'strongReminderIso': strongReminderIso,
      'graceDeadlineIso': graceDeadlineIso,
      'nextReminderAtIso': nextReminderAtIso,
      'confirmedAtIso': confirmedAtIso,
      'resolvedAtIso': resolvedAtIso,
      'wasSuccessful': wasSuccessful,
      'snoozeCount': snoozeCount,
      'summaryShown': summaryShown,
    };
  }

  factory NightlyResult.fromMap(Map<String, dynamic> map) {
    return NightlyResult(
      nightId: map['nightId'] as String,
      bedtimeIso: map['bedtimeIso'] as String,
      gentleReminderIso: map['gentleReminderIso'] as String?,
      strongReminderIso: map['strongReminderIso'] as String,
      graceDeadlineIso: map['graceDeadlineIso'] as String,
      nextReminderAtIso: map['nextReminderAtIso'] as String,
      confirmedAtIso: map['confirmedAtIso'] as String?,
      resolvedAtIso: map['resolvedAtIso'] as String?,
      wasSuccessful: map['wasSuccessful'] as bool?,
      snoozeCount: map['snoozeCount'] as int? ?? 0,
      summaryShown: map['summaryShown'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NightlyResult.fromJson(String source) {
    return NightlyResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
