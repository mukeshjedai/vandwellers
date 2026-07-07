import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/version_config.dart';

class VersionUpdateResult {
  const VersionUpdateResult({
    required this.updateAvailable,
    this.currentVersion,
    this.remoteVersion,
    this.downloadUrl,
  });

  final bool updateAvailable;
  final String? currentVersion;
  final String? remoteVersion;
  final String? downloadUrl;
}

class VersionUpdateService {
  VersionUpdateService._();
  static final VersionUpdateService instance = VersionUpdateService._();

  static const _lastCheckKey = 'vd_last_version_check';
  static const _dismissedVersionKey = 'vd_dismissed_update_version';

  Future<RemoteVersionInfo?> fetchRemoteVersion() async {
    try {
      final response = await http
          .get(Uri.parse(VersionConfig.manifestUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final lines = response.body
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toList();
      if (lines.isEmpty) return null;

      final downloadUrl = lines.length > 1 && _looksLikeUrl(lines[1])
          ? lines[1]
          : null;

      return RemoteVersionInfo(version: lines.first, downloadUrl: downloadUrl);
    } catch (e) {
      debugPrint('Version check failed: $e');
      return null;
    }
  }

  Future<VersionUpdateResult> checkForUpdate({bool force = false}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentLabel = _currentVersionLabel(packageInfo);

    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt(_lastCheckKey) ?? 0;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      if (DateTime.now().difference(lastCheck) < VersionConfig.checkInterval) {
        return VersionUpdateResult(
          updateAvailable: false,
          currentVersion: currentLabel,
        );
      }
    }

    final remote = await fetchRemoteVersion();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

    if (remote == null) {
      return VersionUpdateResult(
        updateAvailable: false,
        currentVersion: currentLabel,
      );
    }

    final dismissed = prefs.getString(_dismissedVersionKey);
    if (dismissed == remote.version) {
      return VersionUpdateResult(
        updateAvailable: false,
        currentVersion: currentLabel,
        remoteVersion: remote.version,
      );
    }

    final updateAvailable = isRemoteNewer(
      remote.version,
      packageInfo.version,
      packageInfo.buildNumber,
    );

    return VersionUpdateResult(
      updateAvailable: updateAvailable,
      currentVersion: currentLabel,
      remoteVersion: remote.version,
      downloadUrl: remote.downloadUrl ?? VersionConfig.defaultDownloadUrl,
    );
  }

  Future<void> dismissVersion(String remoteVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, remoteVersion);
  }

  String _currentVersionLabel(PackageInfo info) =>
      '${info.version} (${info.buildNumber})';

  bool _looksLikeUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  /// Remote is newer if integer build exceeds local build, or semver is greater.
  static bool isRemoteNewer(
    String remote,
    String localVersion,
    String buildNumber,
  ) {
    final remoteInt = int.tryParse(remote);
    final localBuildInt = int.tryParse(buildNumber);
    if (remoteInt != null && localBuildInt != null) {
      return remoteInt > localBuildInt;
    }

    final remoteParts = _parseVersionParts(remote);
    final localParts = _parseVersionParts(localVersion);
    for (var i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final l = i < localParts.length ? localParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }

    if (remoteInt != null && localBuildInt != null) {
      return remoteInt > localBuildInt;
    }
    return remote.trim() != localVersion.trim() &&
        remote.trim() != buildNumber.trim();
  }

  static List<int> _parseVersionParts(String value) {
    final cleaned = value.split(RegExp(r'[^0-9.]')).first;
    return cleaned
        .split('.')
        .where((p) => p.isNotEmpty)
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }
}
