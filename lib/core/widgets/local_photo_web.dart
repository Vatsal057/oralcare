import 'package:flutter/material.dart';

/// Browser-safe replacement for device-local photo rendering.
class LocalPhoto extends StatelessWidget {
  const LocalPhoto({
    super.key,
    required this.path,
    required this.height,
    this.onTap,
  });

  final String path;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(
      child: Text('Photographs are unavailable in the web pilot.'),
    ),
  );
}

class LocalPhotoFullscreen extends StatelessWidget {
  const LocalPhotoFullscreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Photographs are unavailable in the web pilot.')),
  );
}
