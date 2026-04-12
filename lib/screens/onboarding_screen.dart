import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  final AppSettings initialSettings;
  final Future<void> Function(AppSettings settings) onSave;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<int> _leadTimes = <int>[10, 15, 20, 30, 45, 60];

  late TimeOfDay _bedtime;
  late int _leadMinutes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bedtime = widget.initialSettings.bedtime;
    _leadMinutes = widget.initialSettings.reminderLeadMinutes;
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
        gentleReminderEnabled: true,
        soundVibrationEnabled: true,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved as $formatted for bedtime.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedTime = _bedtime.format(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(),
              Text(
                'Sleep Nudger',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Set a bedtime once. We’ll keep the rest calm, simple, and easy to come back to.',
                style: textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _SetupTile(
                label: 'Bedtime',
                value: formattedTime,
                onTap: _pickBedtime,
              ),
              if (_daytimeHint != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _daytimeHint!,
                  style: textTheme.bodyMedium?.copyWith(
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
              const SizedBox(height: 28),
              Text(
                'You’ll get a gentle reminder before bedtime, then a clearer nudge if you are still up.',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: _isSaving ? 'Saving...' : 'Save and continue',
                onPressed: _isSaving ? null : _save,
              ),
              const Spacer(),
            ],
          ),
        ),
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
}

class _SetupTile extends StatelessWidget {
  const _SetupTile({
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
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFF2B36F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
