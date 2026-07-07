import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/version_config.dart';
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
              final url = Uri.parse(
                result.downloadUrl ?? VersionConfig.defaultDownloadUrl,
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (mounted) _dialogVisible = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
