import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/assessment_models.dart';
import '../../data/photo_document_store.dart';
import '../../data/photo_store.dart';
import 'local_photo.dart';

/// Shows a lesion photograph, whichever of the three forms it exists in.
///
/// The forms are not interchangeable and the order matters:
///  1. Held in Firestore as bytes — the current mechanism, and the only one a
///     clinician on another device can read.
///  2. A Firebase Storage URL — legacy, from before the pilot moved off the paid
///     plan. Still readable, so still shown.
///  3. A path on the capturing device — visible only on that phone.
///
/// The device-local path is last because it silently resolves to nothing
/// everywhere else, which previously hid photographs from the reviewing doctor.
class LesionPhotoView extends StatelessWidget {
  const LesionPhotoView({
    super.key,
    required this.assessmentId,
    required this.lesion,
    required this.height,
    this.allowFullScreen = false,
  });

  /// Needed to locate the image document; the lesion row holds only a flag.
  final int? assessmentId;
  final LesionRecord lesion;
  final double height;
  final bool allowFullScreen;

  /// True when there is something this widget can actually display here.
  static bool isViewable({required LesionRecord lesion, int? assessmentId}) =>
      (lesion.hasDatabasePhoto && assessmentId != null) ||
      lesion.hasUploadedPhoto ||
      PhotoStore.exists(lesion.photoPath);

  @override
  Widget build(BuildContext context) {
    if (lesion.hasDatabasePhoto && assessmentId != null && lesion.id != null) {
      return _DatabasePhoto(
        assessmentId: assessmentId!,
        lesionId: lesion.id!,
        height: height,
        allowFullScreen: allowFullScreen,
      );
    }

    if (lesion.hasUploadedPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          lesion.photoUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _Message(
            height: height,
            text: 'Could not load the stored photograph',
          ),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _Spinner(height: height),
        ),
      );
    }

    return LocalPhoto(
      path: lesion.photoPath!,
      height: height,
      onTap: allowFullScreen
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LocalPhotoFullscreen(path: lesion.photoPath!),
              ),
            )
          : null,
    );
  }
}

/// Fetches the image bytes on demand.
///
/// Stateful rather than a bare FutureBuilder so the fetch is not reissued on
/// every rebuild: the read is billed and the document can be a few hundred KB.
class _DatabasePhoto extends StatefulWidget {
  const _DatabasePhoto({
    required this.assessmentId,
    required this.lesionId,
    required this.height,
    required this.allowFullScreen,
  });

  final int assessmentId;
  final int lesionId;
  final double height;
  final bool allowFullScreen;

  @override
  State<_DatabasePhoto> createState() => _DatabasePhotoState();
}

class _DatabasePhotoState extends State<_DatabasePhoto> {
  Future<Uint8List?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<PhotoDocumentStore>().load(
      assessmentId: widget.assessmentId,
      lesionId: widget.lesionId,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _Spinner(height: widget.height);
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        // The flag said a photograph exists, so this is a failure worth naming
        // rather than an empty space the clinician has to interpret.
        return _Message(
          height: widget.height,
          text: 'The photograph could not be loaded.',
        );
      }

      final image = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );

      if (!widget.allowFullScreen) return image;
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _FullscreenBytes(bytes: bytes)),
        ),
        child: image,
      );
    },
  );
}

class _FullscreenBytes extends StatelessWidget {
  const _FullscreenBytes({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient photograph')),
    backgroundColor: Colors.black,
    body: Center(
      child: InteractiveViewer(maxScale: 5, child: Image.memory(bytes)),
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.height, required this.text});

  final double height;
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Center(child: Text(text, textAlign: TextAlign.center)),
  );
}
