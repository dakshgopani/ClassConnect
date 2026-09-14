import 'package:flutter/material.dart';

/// A simple container that constrains its child to a maximum width
/// while centering it horizontally. Useful for adapting mobile‑first
/// layouts to larger desktop screens without fixing the layout width.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({required this.child, super.key, this.maxWidth = 1200});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
