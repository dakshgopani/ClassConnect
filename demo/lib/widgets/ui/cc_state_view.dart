import 'package:flutter/material.dart';

enum CcStateViewType { loading, empty, error }

class CcStateView extends StatelessWidget {
  const CcStateView({
    required this.type,
    required this.title,
    super.key,
    this.message,
    this.onRetry,
  });

  final CcStateViewType type;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    switch (type) {
      case CcStateViewType.loading:
        icon = Icons.hourglass_top_rounded;
      case CcStateViewType.empty:
        icon = Icons.inbox_outlined;
      case CcStateViewType.error:
        icon = Icons.error_outline_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == CcStateViewType.loading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 46, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (type == CcStateViewType.error && onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
