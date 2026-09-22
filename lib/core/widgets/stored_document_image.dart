import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/digilocker_file_store.dart';
import 'fullscreen_image.dart';

/// The image attached to a DigiLocker record, fetched on demand.
///
/// Stateful rather than a bare FutureBuilder so the fetch is not reissued on
/// every rebuild: the read is billed and the document can be several hundred KB.
///
/// [ownerUid] is supplied by the clinician's view so a shared document can be
/// read out of the patient's own collection; the patient's own view leaves it
/// null and the store uses the signed-in uid.
class StoredDocumentImage extends StatefulWidget {
  const StoredDocumentImage({
    super.key,
    required this.recordId,
    required this.title,
    this.ownerUid,
    this.height = 170,
  });

  final String recordId;
  final String title;
  final String? ownerUid;
  final double height;

  @override
  State<StoredDocumentImage> createState() => _StoredDocumentImageState();
}

class _StoredDocumentImageState extends State<StoredDocumentImage> {
  Future<Uint8List?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<DigiLockerFileStore>().load(
      recordId: widget.recordId,
      ownerUid: widget.ownerUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null) {
          // The record said an image exists, so silence here would read as
          // "no attachment" rather than "it did not load".
          return Container(
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'The attached image could not be loaded.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => FullscreenImageView.open(
            context,
            image: MemoryImage(bytes),
            title: widget.title,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    bytes,
                    height: widget.height,
                    width: double.infinity,
                    // A report or a clinical photograph must be shown whole.
                    fit: BoxFit.contain,
                  ),
                ),
                const Positioned(top: 8, right: 8, child: ZoomHint()),
              ],
            ),
          ),
        );
      },
    );
  }
}
