import 'dart:io';

import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => SizedBox(
          height: height,
          child: const Center(child: Text('Could not display image')),
        ),
      ),
    );
    return onTap == null ? image : GestureDetector(onTap: onTap, child: image);
  }
}

class LocalPhotoFullscreen extends StatelessWidget {
  const LocalPhotoFullscreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient photograph')),
    backgroundColor: Colors.black,
    body: Center(
      child: InteractiveViewer(maxScale: 5, child: Image.file(File(path))),
    ),
  );
}
