import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/version_config.dart';
import '../services/apk_update_service.dart';
import '../services/version_update_service.dart';

/// Wraps the app and periodically checks GitHub [versions.txt] for updates.
class UpdateChecker extends StatefulWidget {
  const UpdateChecker({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker>
    with WidgetsBindingObserver {
  Timer? _periodicTimer;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addObserver(this);
    _runCheck(force: true);
    _periodicTimer = Timer.periodic(VersionConfig.checkInterval, (_) {
      _runCheck();
    });
  }

  @override
  void dispose() {
    if (widget.enabled) {
      WidgetsBinding.instance.removeObserver(this);
      _periodicTimer?.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    if (state == AppLifecycleState.resumed) {
      _runCheck();
    }
  }

  Future<void> _runCheck({bool force = false}) async {
    if (!widget.enabled || !mounted || _dialogVisible) return;
    final result = await VersionUpdateService.instance.checkForUpdate(
      force: force,
    );
    if (!mounted || !result.updateAvailable || _dialogVisible) return;
    if (result.remoteVersion == null) return;
    await _showUpdateDialog(result);
  }

  Future<void> _showUpdateDialog(VersionUpdateResult result) async {
    _dialogVisible = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Update available'),
        content: Text(
          'A new version of Van Dwellers is available.\n\n'
          'Installed: ${result.currentVersion}\n'
          'Latest: ${result.remoteVersion}',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await VersionUpdateService.instance
                  .dismissVersion(result.remoteVersion!);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              final url =
                  result.downloadUrl ?? VersionConfig.defaultDownloadUrl;
              Navigator.of(ctx).pop();
              await _startUpdate(url);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (mounted) _dialogVisible = false;
  }

  Future<void> _startUpdate(String url) async {
    if (!mounted) return;

    if (!Platform.isAndroid || !_isDirectApkUrl(url)) {
      await _openInBrowser(url);
      return;
    }

    final progressNotifier = ValueNotifier<double>(0);
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          return AlertDialog(
            title: const Text('Downloading update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value > 0 ? value : null),
                const SizedBox(height: 12),
                Text(
                  value > 0
                      ? '${(value * 100).round()}%'
                      : 'Starting download…',
                ),
              ],
            ),
          );
        },
      ),
    );

    final status = await ApkUpdateService.instance.downloadAndInstall(
      url,
      onProgress: (value) => progressNotifier.value = value,
    );

    progressNotifier.dispose();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    switch (status) {
      case ApkUpdateStatus.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow the prompts to install the update.'),
          ),
        );
      case ApkUpdateStatus.permissionDenied:
        await _showInstallPermissionHelp(url);
      case ApkUpdateStatus.downloadFailed:
      case ApkUpdateStatus.installFailed:
        await _showUpdateFailed(url);
      case ApkUpdateStatus.notAndroid:
        await _openInBrowser(url);
    }
  }

  bool _isDirectApkUrl(String url) =>
      url.toLowerCase().endsWith('.apk') ||
      url.contains('/releases/download/');

  Future<void> _showInstallPermissionHelp(String url) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Install permission needed'),
        content: const Text(
          'Allow Van Dwellers to install updates, then tap Update again.\n\n'
          'Settings → Install unknown apps → Van Dwellers → Allow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: const Text('Open settings'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _openInBrowser(url);
            },
            child: const Text('Download in browser'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateFailed(String url) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update failed'),
        content: const Text(
          'Could not download or install the update automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _openInBrowser(url);
            },
            child: const Text('Open in browser'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
