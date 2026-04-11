import 'package:demo/theme/app_radius.dart';
import 'package:flutter/material.dart';

enum CcButtonVariant { primary, secondary, ghost }

class CcButton extends StatelessWidget {
  const CcButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = CcButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final CcButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color background;
    final Color foreground;
    final Color border;

    switch (variant) {
      case CcButtonVariant.primary:
        background = theme.colorScheme.primary;
        foreground = Colors.white;
        border = Colors.transparent;
      case CcButtonVariant.secondary:
        background = theme.colorScheme.secondaryContainer;
        foreground = theme.colorScheme.onSecondaryContainer;
        border = Colors.transparent;
      case CcButtonVariant.ghost:
        background = Colors.transparent;
        foreground = theme.colorScheme.primary;
        border = theme.colorScheme.primary.withValues(alpha: 0.4);
    }

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
            side: BorderSide(color: border),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
