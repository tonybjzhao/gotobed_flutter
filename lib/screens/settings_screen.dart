import 'package:flutter/material.dart';

import '../models/app_settings.dart';
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
    setState(() {
      _isSaving = true;
    });

    await widget.onSave(
      AppSettings(
        bedtimeHour: _bedtime.hour,
        bedtimeMinute: _bedtime.minute,
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
    });
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
            subtitle: const Text('Send a calm nudge before bedtime.'),
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
            subtitle: const Text('Use notification sound and haptics.'),
          ),
          const SizedBox(height: 24),
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
