import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'app_backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final AppBackupService _service = AppBackupService();
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _service.cleanupStaleTemporaryBackups();
  }

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _status = 'Preparing your backup…';
    });
    try {
      final file = await _service.createPortableBackup();
      if (!mounted) return;
      setState(() => _status = 'Backup created. Choose where to save it.');
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip')],
        subject: 'The Word App Backup',
        text: 'Portable backup of my The Word App data.',
      );
    } on AppBackupException catch (error) {
      if (mounted) setState(() => _status = error.message);
    } catch (error) {
      if (mounted) setState(() => _status = 'Backup failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      allowMultiple: false,
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Validating backup…';
    });
    try {
      final file = File(path);
      final manifest = await _service.validateBackup(file);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore this backup?'),
          content: Text(
            'Backup date: ${manifest.exportedAt.toLocal()}\n\n'
            'Your current local app data will first be saved to an automatic '
            'safety snapshot. The selected backup will then replace the local '
            'data on this device. The app must restart afterward.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _status = 'Creating safety snapshot and restoring…');
      await _service.restoreBackup(file);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restore complete'),
          content: const Text(
            'Your backup has been restored successfully. The Word App will now '
            'close so all restored data can be loaded cleanly. Open it again '
            'from your Home screen or Google Play.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close app'),
            ),
          ],
        ),
      );
      await SystemNavigator.pop();
    } on AppBackupException catch (error) {
      if (mounted) setState(() => _status = error.message);
    } catch (error) {
      if (mounted) setState(() => _status = 'Restore failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.shield_outlined,
            size: 52,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Protect your local Bible study data',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The backup includes your private local app data, including notes, '
            'favorites, reading progress, sermon notes and recordings, Scripture '
            'Memory progress, devotional journal data, settings, notifications, '
            'user tracts, and Word Studio backgrounds stored on this device.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Export My Data'),
              subtitle: const Text(
                'Create an integrity-checked ZIP backup and save it to Files, '
                'Google Drive, OneDrive, or another safe location. The ZIP is '
                'not encrypted.',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_busy,
              onTap: _busy ? null : _export,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore_rounded),
              title: const Text('Restore Backup'),
              subtitle: const Text(
                'Validate and restore a previous The Word App backup. A safety '
                'snapshot is created automatically before replacement.',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_busy,
              onTap: _busy ? null : _restore,
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Important: The backup ZIP is not encrypted. Anyone with the file '
              'may be able to read personal notes, journal entries, sermon '
              'recordings, selected images, and Scripture study data. The app '
              'does not upload it automatically; you choose where to save or '
              'share it, so keep it private.',
            ),
          ),
        ],
      ),
    );
  }
}
