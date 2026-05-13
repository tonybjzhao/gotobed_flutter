import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = widget.onPressed == null
            ? 0.0
            : Tween<double>(
                begin: 0.09,
                end: 0.15,
              ).transform(_glowController.value);

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            boxShadow: widget.onPressed == null
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFF2B36F).withValues(alpha: glow),
                      blurRadius: 18 + (_glowController.value * 8),
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: FilledButton(
        onPressed: widget.onPressed == null
            ? null
            : () async {
                await widget.onPressed!();
              },
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            Size.fromHeight(widget.dense ? 50 : 54),
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
        child: Text(widget.label),
      ),
    );
  }
}
