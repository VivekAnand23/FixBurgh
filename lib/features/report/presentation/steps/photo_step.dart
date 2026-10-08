import 'dart:io';

import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PhotoStep extends ConsumerWidget {
  const PhotoStep({required this.onNext, super.key});

  final VoidCallback onNext;

  Future<void> _pick(WidgetRef ref, ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      requestFullMetadata: false,
    );
    if (file != null) {
      await ref.read(reportDraftProvider.notifier).addPhoto(file.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(reportDraftProvider);
    final full = draft.photoPaths.length >= maxPhotos;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.photoTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.photoBody(maxPhotos)),
        const SizedBox(height: 24),
        if (draft.photoPaths.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (i, path) in draft.photoPaths.indexed)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        semanticLabel: l10n.photoNumber(i + 1),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filledTonal(
                        tooltip: l10n.removePhoto,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => ref
                            .read(reportDraftProvider.notifier)
                            .removePhoto(path),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: full ? null : () => _pick(ref, ImageSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.takePhoto),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: full ? null : () => _pick(ref, ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l10n.chooseFromLibrary),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: draft.hasPhoto ? onNext : null,
          child: Text(l10n.next),
        ),
      ],
    );
  }
}
