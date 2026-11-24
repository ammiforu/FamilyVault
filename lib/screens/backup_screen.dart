import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  void _exportCloudJson() {
    final jsonStr = StorageService.instance.exportCloudBackupJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Encrypted Cloud Backup bundle copied! You can save it to Google Drive, iCloud, or Notes.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restoreCloudJsonDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Cloud Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup JSON or encrypted bundle from Google Drive / iCloud below:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final content = textCtrl.text.trim();
              if (content.isEmpty) return;

              final success = await StorageService.instance.restoreCloudBackupJson(content);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✓ Entire Family Vault restored successfully!' : 'Failed to parse backup format.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Restore Vault'),
          ),
        ],
      ),
    );
  }

  void _exportCsvDialog() {
    final csv = StorageService.instance.exportAllToCsv();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All Family Data (Wealth, Vehicles, Properties, Receipts, Passwords) copied in CSV format! Ready for Google Sheets.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importSmartCsvDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smart Google Sheets Import'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste rows from your Google Sheets or Excel spreadsheet. Our smart engine will automatically categorize them into Wealth, Vehicles, Properties, Warranties, and Passwords!',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste Google Sheet CSV rows here...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final content = textCtrl.text.trim();
              if (content.isEmpty) return;

              final count = await StorageService.instance.importSmartCsv(content);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Successfully imported $count items across all family modules!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Import Rows'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Cloud Backup & Privacy'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PRIVACY GUARANTEE BANNER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withAlpha(80)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_person_rounded, color: Colors.green, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Local-First & Zero-Knowledge',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your wealth, vehicles, deeds, receipts, and passwords never touch third-party servers. All data is encrypted directly on your device. You can sync or backup to your own personal Google Drive, iCloud, or local storage anytime.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CLOUD BACKUP OPTIONS
          Text('Personal Cloud Sync (Google Drive / iCloud)', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                  title: const Text('Export Cloud Backup Bundle'),
                  subtitle: const Text('Generates full encrypted backup for GDrive/iCloud'),
                  trailing: const Icon(Icons.copy_rounded),
                  onTap: _exportCloudJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.teal),
                  title: const Text('Restore Cloud Backup Bundle'),
                  subtitle: const Text('Restore family assets from GDrive/iCloud backup'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _restoreCloudJsonDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // GOOGLE SHEETS FULL INTEGRATION
          Text('Google Sheets & Spreadsheet Sync', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: Colors.green),
                  title: const Text('Export Everything to CSV'),
                  subtitle: const Text('Wealth, Vehicles, Properties, Receipts & Passwords'),
                  trailing: const Icon(Icons.copy_rounded),
                  onTap: _exportCsvDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
                  title: const Text('Smart Import from Google Sheets'),
                  subtitle: const Text('Intelligently parses & distributes columns to modules'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _importSmartCsvDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
