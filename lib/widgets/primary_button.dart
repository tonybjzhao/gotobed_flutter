import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.dense = false,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed == null
          ? null
          : () async {
              await onPressed!();
            },
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: const Color(0xFFF2B36F),
        foregroundColor: const Color(0xFF2B1802),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
