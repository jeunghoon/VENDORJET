import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: scheme.surfaceContainerHighest,
        content: Text(
          message,
          style: TextStyle(color: scheme.onSurface),
        ),
      ),
    );
  }
}

