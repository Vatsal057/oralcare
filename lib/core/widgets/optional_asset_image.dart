import 'package:flutter/material.dart';

import 'fullscreen_image.dart';

/// An illustration that may not have been drawn yet.
///
/// The content catalogues name an image for every education topic, exercise and
/// risk factor, but the artwork arrives in batches. Referencing a missing asset
/// with a plain [Image.asset] renders a broken-image box, so each of these
/// degrades to nothing instead: the surrounding card simply has no picture until
/// the file lands, and no code change is needed when it does.
///
/// Always [BoxFit.contain]. Cover crops to fill, which is how 17-39% of the
/// self-examination illustrations went missing without anything on screen saying
/// so.
class OptionalAssetImage extends StatelessWidget {
  const OptionalAssetImage({
    super.key,
    required this.assetPath,
    this.height = 170,
    this.title,
    this.allowFullScreen = true,
    this.borderRadius = 12,
  });

  /// Null or empty renders nothing at all.
  final String? assetPath;

  final double height;

  /// Caption for the full-screen view. Falls back to a neutral title.
  final String? title;

  final bool allowFullScreen;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        // The asset is not in the bundle yet. Collapse silently rather than
        // showing a broken frame the reader has to interpret.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: allowFullScreen
          ? GestureDetector(
              onTap: () => FullscreenImageView.open(
                context,
                image: AssetImage(path),
                title: title ?? 'Illustration',
              ),
              child: Stack(
                children: [
                  image,
                  const Positioned(top: 8, right: 8, child: ZoomHint()),
                ],
              ),
            )
          : image,
    );
  }
}
