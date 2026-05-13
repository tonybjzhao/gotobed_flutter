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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: onPressed == null
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFF2B36F).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: FilledButton(
        onPressed: onPressed == null
            ? null
            : () async {
                await onPressed!();
              },
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            Size.fromHeight(dense ? 50 : 54),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF7C6A58);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE7A55F);
            }
            return const Color(0xFFF0AD64);
          }),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF261602)),
          overlayColor: WidgetStateProperty.all(
            const Color(0xFFFFFFFF).withValues(alpha: 0.08),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
