import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onCancel,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings settings) onSave;
  final VoidCallback onCancel;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _leadTimes = <int>[10, 15, 20, 30, 45, 60];

  late TimeOfDay _bedtime;
  late int _leadMinutes;
  late bool _gentleReminderEnabled;
  late bool _soundVibrationEnabled;
  bool _isSaving = false;
  bool _isTestingNotification = false;

  @override
  void initState() {
    super.initState();
    _bedtime = widget.settings.bedtime;
    _leadMinutes = widget.settings.reminderLeadMinutes;
    _gentleReminderEnabled = widget.settings.gentleReminderEnabled;
    _soundVibrationEnabled = widget.settings.soundVibrationEnabled;
  }

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _bedtime = picked;
    });
  }

  Future<void> _save() async {
    final correctedFromDaytime = _isLikelyAfternoonBedtime(_bedtime);
    final bedtimeToSave = _normalizedBedtimeForSave();

    setState(() {
      _isSaving = true;
    });

    await widget.onSave(
      AppSettings(
        bedtimeHour: bedtimeToSave.hour,
        bedtimeMinute: bedtimeToSave.minute,
        reminderLeadMinutes: _leadMinutes,
        gentleReminderEnabled: _gentleReminderEnabled,
        soundVibrationEnabled: _soundVibrationEnabled,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _bedtime = bedtimeToSave;
    });

    if (correctedFromDaytime) {
      final formatted = MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(bedtimeToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved as $formatted for bedtime.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          _SettingsTile(
            label: 'Bedtime',
            value: MaterialLocalizations.of(context).formatTimeOfDay(_bedtime),
            onTap: _pickBedtime,
          ),
          if (_daytimeHint != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _daytimeHint!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFF2B36F),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          InputDecorator(
            decoration: _decoration('Reminder lead time'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _leadMinutes,
                dropdownColor: const Color(0xFF211B2A),
                items: _leadTimes
                    .map(
                      (minutes) => DropdownMenuItem<int>(
                        value: minutes,
                        child: Text('$minutes minutes'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _leadMinutes = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _gentleReminderEnabled,
            onChanged: (value) {
              setState(() {
                _gentleReminderEnabled = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Gentle reminder'),
            subtitle: const Text('Start softly before bedtime.'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _soundVibrationEnabled,
            onChanged: (value) {
              setState(() {
                _soundVibrationEnabled = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound and vibration'),
            subtitle: const Text('Add sound and haptics to bedtime nudges.'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _isTestingNotification ? null : _sendTestNotification,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Color(0x55F2B36F)),
              foregroundColor: const Color(0xFFF2B36F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isTestingNotification
                  ? 'Scheduling test notification...'
                  : 'Try a test nudge (5 sec)',
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _isSaving ? 'Saving...' : 'Save changes',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF211B2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  String? get _daytimeHint {
    if (!_isLikelyAfternoonBedtime(_bedtime)) {
      return null;
    }

    final amTime = TimeOfDay(hour: _bedtime.hour - 12, minute: _bedtime.minute);
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(amTime);
    return 'That looks like daytime. Did you mean $formatted?';
  }

  TimeOfDay _normalizedBedtimeForSave() {
    if (!_isLikelyAfternoonBedtime(_bedtime)) {
      return _bedtime;
    }

    return TimeOfDay(hour: _bedtime.hour - 12, minute: _bedtime.minute);
  }

  bool _isLikelyAfternoonBedtime(TimeOfDay time) {
    return time.period == DayPeriod.pm && time.hour >= 12 && time.hour < 18;
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isTestingNotification = true;
    });

    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.scheduleTestNotification(
      soundEnabled: _soundVibrationEnabled,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isTestingNotification = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification scheduled for 5 seconds from now.'),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF211B2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: <Widget>[
            Text(label),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFF2B36F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
