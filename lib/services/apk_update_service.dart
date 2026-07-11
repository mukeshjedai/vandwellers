import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ApkUpdateStatus {
  success,
  downloadFailed,
  installFailed,
  permissionDenied,
  notAndroid,
}

class ApkUpdateService {
  ApkUpdateService._();
  static final ApkUpdateService instance = ApkUpdateService._();

  Future<ApkUpdateStatus> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) return ApkUpdateStatus.notAndroid;

    if (!await _ensureInstallPermission()) {
      return ApkUpdateStatus.permissionDenied;
    }

    try {
      final file = await _downloadApk(url, onProgress: onProgress);
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type == ResultType.done) {
        return ApkUpdateStatus.success;
      }
      debugPrint('APK install intent failed: ${result.message}');
      return ApkUpdateStatus.installFailed;
    } catch (e, st) {
      debugPrint('APK update failed: $e\n$st');
      return ApkUpdateStatus.downloadFailed;
    }
  }

  Future<bool> _ensureInstallPermission() async {
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;

    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }

  Future<File> _downloadApk(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(url);
    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/VanDwellers-update.apk');
      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      await response.stream.forEach((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress?.call(receivedBytes / totalBytes);
        }
      });
      await sink.close();

      if (totalBytes > 0 && receivedBytes < totalBytes) {
        throw HttpException('Download incomplete');
      }

      onProgress?.call(1);
      return file;
    } finally {
      client.close();
    }
  }
}
