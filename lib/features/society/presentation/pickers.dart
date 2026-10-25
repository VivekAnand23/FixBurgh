import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a photo with the camera or from the library (an image_picker
/// source). Overridden in tests.
final pickImageProvider = Provider<Future<File?> Function(ImageSource)>(
  (ref) => (source) async {
    final shot = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 85,
    );
    return shot == null ? null : File(shot.path);
  },
);

/// Picks a file with one of the given extensions from Files. Overridden
/// in tests.
final pickFileProvider = Provider<Future<File?> Function(List<String>)>(
  (ref) => (extensions) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    final path = picked?.path;
    return path == null ? null : File(path);
  },
);

/// Picks a short video from the library. Overridden in tests.
final pickVideoProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    final clip = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    return clip == null ? null : File(clip.path);
  },
);
