import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final _picker = ImagePicker();

  Future<bool> ensurePhotosPermission() async {
    if (kIsWeb) return true;
    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<File?> pickPhoto({required ImageSource source}) async {
    final allowed = await ensurePhotosPermission();
    if (!allowed) return null;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<List<File>> pickPhotos({ImageSource source = ImageSource.gallery}) async {
    final allowed = await ensurePhotosPermission();
    if (!allowed) return [];

    final picked = await _picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    return picked.map((item) => File(item.path)).toList();
  }
}
