import 'package:flutter/material.dart';

class ProductTagPill extends StatelessWidget {
  final String label;
  final bool highlight;

  const ProductTagPill({
    super.key,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = highlight ? scheme.errorContainer : scheme.secondaryContainer;
    final foreground = highlight ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
