import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/primary_button.dart';

// Channel for opening the platform notification settings screen.
const MethodChannel _settingsChannel = MethodChannel(
  'com.in5km.gotobed/settings',
);

Future<void> _openNotificationSettings() async {
  try {
    await _settingsChannel.invokeMethod<void>('openNotificationSettings');
  } catch (_) {
    // ignore on platforms that don't support it
  }
}

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
  late ReminderSoundProfile _reminderSoundProfile;
  bool _isSaving = false;
  bool _isTestingNotification = false;

  @override
  void initState() {
    super.initState();
    _bedtime = widget.settings.bedtime;
    _leadMinutes = widget.settings.reminderLeadMinutes;
    _gentleReminderEnabled = widget.settings.gentleReminderEnabled;
    _soundVibrationEnabled = widget.settings.soundVibrationEnabled;
    _reminderSoundProfile = widget.settings.reminderSoundProfile;
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
        reminderSoundProfile: _reminderSoundProfile,
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Settings'),
      ),
      bottomNavigationBar:
          AdService.bannerAdEnabled && AdService.showBannerOnSettingsOnly
          ? const AdBanner()
          : null,
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + bottomPadding),
          children: <Widget>[
            _SettingsSection(
              title: 'Bedtime',
              children: <Widget>[
                _SettingsTile(
                  label: 'Bedtime',
                  value: MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(_bedtime),
                  onTap: _pickBedtime,
                ),
              ],
            ),
            if (_daytimeHint != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _daytimeHint!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFF2B36F),
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'Reminder',
              children: <Widget>[
                _SettingsDropdown<int>(
                  label: 'Lead time',
                  value: _leadMinutes,
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
                const _SettingsDivider(),
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
              ],
            ),
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'Sound',
              children: <Widget>[
                SwitchListTile(
                  value: _soundVibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundVibrationEnabled = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound and vibration'),
                  subtitle: const Text(
                    'Add sound and haptics to bedtime nudges.',
                  ),
                ),
                const _SettingsDivider(),
                _SettingsDropdown<ReminderSoundProfile>(
                  label: 'Reminder sound',
                  value: _reminderSoundProfile,
                  enabled: _soundVibrationEnabled,
                  items: ReminderSoundProfile.values
                      .map(
                        (profile) => DropdownMenuItem<ReminderSoundProfile>(
                          value: profile,
                          child: Text(profile.label),
                        ),
                      )
                      .toList(),
                  onChanged: _soundVibrationEnabled
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _reminderSoundProfile = value;
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'If reminders arrive late on some Android phones, disable battery optimization for GoToBed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFCBB9A6),
                height: 1.45,
              ),
            ),
            if (_iosSoundHint != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _iosSoundHint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFCBB9A6),
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showReminderTroubleshootingSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF2B36F),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Troubleshoot delayed reminders'),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _isTestingNotification ? null : _sendTestNotification,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0x55F2B36F)),
                foregroundColor: const Color(0xFFF2B36F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                _isTestingNotification
                    ? 'Scheduling test notification...'
                    : 'Try a test nudge (5 sec)',
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save changes',
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
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

  String? get _iosSoundHint {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    return 'On iPhone, if reminders are silent, check Focus mode, the hardware silent switch, and notification sounds for GoToBed in iOS Settings.';
  }

  Future<void> _sendTestNotification() async {
    if (!_soundVibrationEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turn on Sound and vibration to hear the test nudge.'),
        ),
      );
      return;
    }

    setState(() {
      _isTestingNotification = true;
    });

    try {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleTestNotification(
        soundEnabled: _soundVibrationEnabled,
        soundProfile: _reminderSoundProfile,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTestingNotification = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to schedule test nudge. Check notification permission and try again.',
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isTestingNotification = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test notification sent — check your notification shade.',
        ),
      ),
    );
  }

  Future<void> _showReminderTroubleshootingSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        final steps = <String>[
          '1. Open system settings and search for "Battery optimization".',
          '2. Find GoToBed and set it to "Not optimized" or "Unrestricted".',
          '3. In App info, allow notifications, sound, and background activity.',
          '4. Run a 2-minute test after saving bedtime changes.',
        ];

        final brandHints = <String>[
          'Xiaomi/Redmi: Security > Battery > App battery saver > GoToBed > No restrictions.',
          'Huawei/Honor: Battery > App launch > GoToBed > Manage manually (enable all toggles).',
          'Samsung: Battery > Background usage limits > Never sleeping apps > add GoToBed.',
          'OnePlus/Oppo/Vivo: Battery > App battery management > GoToBed > Allow background activity.',
          'Pixel: App info > App battery usage > Allow background usage.',
        ];

        final copyText = <String>[
          'GoToBed reminder troubleshooting',
          '',
          ...steps,
          '',
          'Brand-specific hints',
          ...brandHints,
        ].join('\n');

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              32 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D516A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Reminder Troubleshooting',
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Some Android phones delay scheduled notifications to save power. Try these steps:',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFCBB9A6),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                ...steps.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      step,
                      style: Theme.of(
                        sheetContext,
                      ).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Brand-specific hints',
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFF2B36F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...brandHints.map(
                  (hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      hint,
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(
                            color: const Color(0xFFCBB9A6),
                            height: 1.35,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: copyText),
                          );
                          if (!sheetContext.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Troubleshooting steps copied.'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF2B36F),
                          side: const BorderSide(color: Color(0x55F2B36F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy steps'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openNotificationSettings,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF2B36F),
                          side: const BorderSide(color: Color(0x55F2B36F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                        ),
                        label: const Text('Notification settings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFCBB9A6).withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF211B2A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFCBB9A6).withValues(alpha: 0.07),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFCBB9A6).withValues(alpha: 0.11),
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
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: <Widget>[
            Text(label),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFF2B36F),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0x997C7188),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: enabled
          ? const Color(0xFFF2B36F)
          : const Color(0xFFCBB9A6).withValues(alpha: 0.45),
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: enabled
                    ? const Color(0xFFF9F1E7)
                    : const Color(0xFFCBB9A6).withValues(alpha: 0.55),
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              dropdownColor: const Color(0xFF211B2A),
              icon: Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: enabled
                    ? const Color(0xFFF2B36F)
                    : const Color(0xFFCBB9A6).withValues(alpha: 0.4),
              ),
              style: valueStyle,
              items: items,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
