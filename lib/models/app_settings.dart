import 'dart:convert';

import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.reminderLeadMinutes,
    required this.gentleReminderEnabled,
    required this.soundVibrationEnabled,
  });

  final int bedtimeHour;
  final int bedtimeMinute;
  final int reminderLeadMinutes;
  final bool gentleReminderEnabled;
  final bool soundVibrationEnabled;

  static const int defaultGracePeriodMinutes = 20;

  factory AppSettings.defaults() {
    return const AppSettings(
      bedtimeHour: 23,
      bedtimeMinute: 0,
      reminderLeadMinutes: 30,
      gentleReminderEnabled: true,
      soundVibrationEnabled: true,
    );
  }

  TimeOfDay get bedtime => TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute);

  AppSettings copyWith({
    int? bedtimeHour,
    int? bedtimeMinute,
    int? reminderLeadMinutes,
    bool? gentleReminderEnabled,
    bool? soundVibrationEnabled,
  }) {
    return AppSettings(
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
      bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      gentleReminderEnabled:
          gentleReminderEnabled ?? this.gentleReminderEnabled,
      soundVibrationEnabled:
          soundVibrationEnabled ?? this.soundVibrationEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bedtimeHour': bedtimeHour,
      'bedtimeMinute': bedtimeMinute,
      'reminderLeadMinutes': reminderLeadMinutes,
      'gentleReminderEnabled': gentleReminderEnabled,
      'soundVibrationEnabled': soundVibrationEnabled,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      bedtimeHour: map['bedtimeHour'] as int? ?? 23,
      bedtimeMinute: map['bedtimeMinute'] as int? ?? 0,
      reminderLeadMinutes: map['reminderLeadMinutes'] as int? ?? 30,
      gentleReminderEnabled: map['gentleReminderEnabled'] as bool? ?? true,
      soundVibrationEnabled: map['soundVibrationEnabled'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) {
    return AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
