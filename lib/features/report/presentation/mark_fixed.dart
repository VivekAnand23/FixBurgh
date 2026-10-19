import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// "Mark fixed" from My Reports or the report detail, with an optional
/// "after" photo (BRD FR-MYR-02).
Future<void> markFixedFlow(
  BuildContext context,
  WidgetRef ref,
  Report report,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showModalBottomSheet<_AfterPhoto>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              l10n.markFixedTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.markFixedBody),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.afterPhotoCamera),
            onTap: () => Navigator.pop(context, _AfterPhoto.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.afterPhotoGallery),
            onTap: () => Navigator.pop(context, _AfterPhoto.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.task_alt),
            title: Text(l10n.markFixedNoPhoto),
            onTap: () => Navigator.pop(context, _AfterPhoto.none),
          ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  String? path;
  if (choice != _AfterPhoto.none) {
    final file = await ImagePicker().pickImage(
      source: choice == _AfterPhoto.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2400,
      requestFullMetadata: false,
    );
    if (file == null) return;
    path = file.path;
  }
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return;
  if (path != null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.uploadingPhoto)));
  }
  try {
    await ref
        .read(reportRepositoryProvider)
        .markResolved(report.id, uid: uid, afterPhotoPath: path);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.markedFixed)));
  } on Exception {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
  }
}

enum _AfterPhoto { camera, gallery, none }
