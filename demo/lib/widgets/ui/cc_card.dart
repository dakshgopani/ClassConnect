import 'dart:ui';

import 'package:demo/theme/app_radius.dart';
import 'package:flutter/material.dart';

class CcCard extends StatelessWidget {
  const CcCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glass
            ? theme.colorScheme.surface.withValues(alpha: 0.82)
            : theme.colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (!glass) return card;

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: card,
      ),
    );
  }
}
