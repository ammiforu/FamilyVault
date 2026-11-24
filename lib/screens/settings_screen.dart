import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';
import 'lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _changePinDialog() {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Master PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current PIN'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New 4-6 Digit PIN'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Confirm New PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final oldValid = await StorageService.instance.verifyMasterPin(oldPinCtrl.text);
              if (!oldValid) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Current PIN is incorrect!'), behavior: SnackBarBehavior.floating),
                  );
                }
                return;
              }
              if (newPinCtrl.text.length < 4 || newPinCtrl.text != confirmPinCtrl.text) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New PINs must match and be at least 4 digits!'), behavior: SnackBarBehavior.floating),
                  );
                }
                return;
              }
              await StorageService.instance.setupMasterPin(newPinCtrl.text);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Master PIN updated successfully!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  void _exportJsonBackup() {
    final jsonStr = StorageService.instance.exportToCsv(); // CSV format
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full Vault backup copied to clipboard! Save it securely.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _lockNow() {
    StorageService.instance.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LockScreen(isConfigured: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = StorageService.instance.items.length;
    final logins = StorageService.instance.items.where((i) => i.category == VaultCategory.login).length;
    final cards = StorageService.instance.items.where((i) => i.category == VaultCategory.card).length;
    final docs = StorageService.instance.items.where((i) => i.category == VaultCategory.document).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vault Stats Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vault Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(count: totalItems.toString(), label: 'Total Items'),
                      _StatColumn(count: logins.toString(), label: 'Logins'),
                      _StatColumn(count: cards.toString(), label: 'Cards'),
                      _StatColumn(count: docs.toString(), label: 'Documents'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Security Section
          Text('Security & Protection', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('Change Master PIN'),
                  subtitle: const Text('Update your local security PIN code'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _changePinDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_clock_outlined),
                  title: const Text('Lock Vault Now'),
                  subtitle: const Text('Immediately lock and require PIN to re-enter'),
                  trailing: const Icon(Icons.lock_rounded, color: Colors.orange),
                  onTap: _lockNow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Backup & Data
          Text('Spreadsheet & Backup', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_view_outlined, color: Colors.green),
                  title: const Text('Export to CSV / Google Sheets'),
                  subtitle: const Text('Copy full spreadsheet records to clipboard'),
                  trailing: const Icon(Icons.copy_rounded),
                  onTap: _exportJsonBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Appearance
          Text('Preferences', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(widget.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                  title: const Text('Dark Mode'),
                  value: widget.isDarkMode,
                  onChanged: (val) => widget.onThemeToggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // App Info
          Center(
            child: Column(
              children: [
                const Icon(Icons.shield_rounded, size: 36, color: Colors.blue),
                const SizedBox(height: 4),
                const Text('FamilyVault v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'End-to-End Local Encrypted Vault for Android & iOS',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String count;
  final String label;

  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(count, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
