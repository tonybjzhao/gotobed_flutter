import 'dart:convert';

import 'package:flutter/material.dart';

enum ReminderSoundProfile { system, softVoice }

extension ReminderSoundProfileX on ReminderSoundProfile {
  String get storageKey {
    switch (this) {
      case ReminderSoundProfile.system:
        return 'system';
      case ReminderSoundProfile.softVoice:
        return 'soft_voice';
    }
  }

  String get label {
    switch (this) {
      case ReminderSoundProfile.system:
        return 'System chime';
      case ReminderSoundProfile.softVoice:
        return 'Soft voice';
    }
  }

  static ReminderSoundProfile fromStorage(String? raw) {
    switch (raw) {
      case 'soft_voice':
        return ReminderSoundProfile.softVoice;
      case 'system':
      default:
        return ReminderSoundProfile.system;
    }
  }
}

class AppSettings {
  const AppSettings({
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.reminderLeadMinutes,
    required this.gentleReminderEnabled,
    required this.soundVibrationEnabled,
    this.reminderSoundProfile = ReminderSoundProfile.system,
  });

  final int bedtimeHour;
  final int bedtimeMinute;
  final int reminderLeadMinutes;
  final bool gentleReminderEnabled;
  final bool soundVibrationEnabled;
  final ReminderSoundProfile reminderSoundProfile;

  static const int defaultGracePeriodMinutes = 20;

  factory AppSettings.defaults() {
    return const AppSettings(
      bedtimeHour: 23,
      bedtimeMinute: 0,
      reminderLeadMinutes: 30,
      gentleReminderEnabled: true,
      soundVibrationEnabled: true,
      reminderSoundProfile: ReminderSoundProfile.system,
    );
  }

  TimeOfDay get bedtime => TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute);

  AppSettings copyWith({
    int? bedtimeHour,
    int? bedtimeMinute,
    int? reminderLeadMinutes,
    bool? gentleReminderEnabled,
    bool? soundVibrationEnabled,
    ReminderSoundProfile? reminderSoundProfile,
  }) {
    return AppSettings(
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
      bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      gentleReminderEnabled:
          gentleReminderEnabled ?? this.gentleReminderEnabled,
      soundVibrationEnabled:
          soundVibrationEnabled ?? this.soundVibrationEnabled,
      reminderSoundProfile: reminderSoundProfile ?? this.reminderSoundProfile,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bedtimeHour': bedtimeHour,
      'bedtimeMinute': bedtimeMinute,
      'reminderLeadMinutes': reminderLeadMinutes,
      'gentleReminderEnabled': gentleReminderEnabled,
      'soundVibrationEnabled': soundVibrationEnabled,
      'reminderSoundProfile': reminderSoundProfile.storageKey,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      bedtimeHour: map['bedtimeHour'] as int? ?? 23,
      bedtimeMinute: map['bedtimeMinute'] as int? ?? 0,
      reminderLeadMinutes: map['reminderLeadMinutes'] as int? ?? 30,
      gentleReminderEnabled: map['gentleReminderEnabled'] as bool? ?? true,
      soundVibrationEnabled: map['soundVibrationEnabled'] as bool? ?? true,
      reminderSoundProfile: ReminderSoundProfileX.fromStorage(
        map['reminderSoundProfile'] as String?,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) {
    return AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
