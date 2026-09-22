import 'package:flutter/material.dart';

/// Full-screen, zoomable view of any image.
///
/// Takes an [ImageProvider] rather than a path or bytes so one viewer serves
/// bundled illustrations, captured photographs and stored photo bytes alike.
///
/// [BoxFit.contain] is not a style choice here. A clinical illustration or a
/// lesion photograph shown with [BoxFit.cover] is cropped to fill its box, and
/// the cropped-away part is exactly what the viewer was trying to look at.
class FullscreenImageView extends StatelessWidget {
  const FullscreenImageView({
    super.key,
    required this.image,
    this.title = 'Image',
  });

  final ImageProvider image;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: SafeArea(
      child: Center(
        child: InteractiveViewer(
          maxScale: 6,
          child: Image(
            image: image,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Text(
                'This image could not be displayed.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// Pushes the viewer. Kept here so every caller opens it the same way.
  static void open(
    BuildContext context, {
    required ImageProvider image,
    String title = 'Image',
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FullscreenImageView(image: image, title: title),
    ),
  );
}

/// A small "tap to enlarge" affordance, so it is obvious the whole image is
/// available rather than leaving the viewer wondering what was cut off.
class ZoomHint extends StatelessWidget {
  const ZoomHint({super.key, this.label = 'Tap to enlarge'});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.zoom_in, color: Colors.white, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11.5),
        ),
      ],
    ),
  );
}
