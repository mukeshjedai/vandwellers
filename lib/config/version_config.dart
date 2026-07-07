/// Remote version manifest for Van Dwellers.
/// https://github.com/mukeshjedai/vandwellers/blob/main/versions.txt
class VersionConfig {
  static const manifestUrl =
      'https://raw.githubusercontent.com/mukeshjedai/vandwellers/main/versions.txt';

  /// Default download page when manifest has no URL on line 2.
  static const defaultDownloadUrl =
      'https://github.com/mukeshjedai/vandwellers/releases/latest';

  /// Minimum interval between background checks.
  static const checkInterval = Duration(hours: 6);
}

class RemoteVersionInfo {
  const RemoteVersionInfo({
    required this.version,
    this.downloadUrl,
  });

  final String version;
  final String? downloadUrl;
}
