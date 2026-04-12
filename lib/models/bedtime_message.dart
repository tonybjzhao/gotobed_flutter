import 'bedtime_tone.dart';

class BedtimeMessage {
  const BedtimeMessage({
    required this.tone,
    required this.title,
    this.subtitle,
  });

  final BedtimeTone tone;
  final String title;
  final String? subtitle;
}
