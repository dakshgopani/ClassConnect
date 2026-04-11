import 'package:flutter/material.dart';

class CcDecoratedBackground extends StatelessWidget {
  const CcDecoratedBackground({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF7FAFF),
                  Color(0xFFEAF3FF),
                  Color(0xFFFDFEFF),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _SoftCircle(
            color: const Color(0xFF7CCBFF).withValues(alpha: 0.20),
            size: 220,
          ),
        ),
        Positioned(
          top: 120,
          left: -70,
          child: _SoftCircle(
            color: const Color(0xFF7EE7C4).withValues(alpha: 0.18),
            size: 180,
          ),
        ),
        Positioned(
          bottom: -90,
          right: -40,
          child: _SoftCircle(
            color: const Color(0xFF9EC5FF).withValues(alpha: 0.16),
            size: 200,
          ),
        ),
        if (padding != null)
          Padding(padding: padding!, child: child)
        else
          child,
      ],
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
