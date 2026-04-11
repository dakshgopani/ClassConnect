import 'package:flutter/material.dart';

Future<T?> showCcDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: true,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      );
    },
  );
}
