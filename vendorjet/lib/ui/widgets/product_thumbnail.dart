import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double aspectRatio;
  final double borderRadius;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 4 / 3,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: scheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.image_outlined,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        size: 32,
      ),
    );

    final image = imageUrl == null || imageUrl!.isEmpty
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return placeholder;
              },
            ),
          );

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      ),
    );
  }
}
