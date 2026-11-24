import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';
import 'item_detail_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  void _copy(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emergencyItems = StorageService.instance.items
        .where((it) => it.category == VaultCategory.emergency)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.medical_services_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Emergency & ICE Hub'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'In Case of Emergency (ICE)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instant access to doctors, medical alerts, blood types, and family emergency contacts.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick 911 / Emergency Info Card
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _EmergencyAction(label: 'Emergency Police / Fire', number: '911', icon: Icons.local_police_rounded),
                  _EmergencyAction(label: 'Poison Control', number: '1-800-222-1222', icon: Icons.health_and_safety_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Family Emergency Contacts (${emergencyItems.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          if (emergencyItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.contact_phone_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No emergency contacts added yet.'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Emergency Contact'),
                        onPressed: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ItemDetailScreen(initialCategory: VaultCategory.emergency),
                            ),
                          );
                          if (res == true) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...emergencyItems.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.health_and_safety_rounded, color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'For: ${item.assignedMember}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              final res = await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                              );
                              if (res == true) setState(() {});
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      if (item.username.isNotEmpty)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_rounded, color: Colors.green),
                          title: Text(item.username),
                          subtitle: const Text('Primary Contact'),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () => _copy(item.username, 'Phone number'),
                          ),
                        ),
                      if (item.password.isNotEmpty)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_iphone_rounded, color: Colors.blue),
                          title: Text(item.password),
                          subtitle: const Text('Secondary / Alternative Phone'),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () => _copy(item.password, 'Alternative phone'),
                          ),
                        ),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.notes,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ItemDetailScreen(initialCategory: VaultCategory.emergency),
            ),
          );
          if (res == true) setState(() {});
        },
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Add ICE Contact'),
      ),
    );
  }
}

class _EmergencyAction extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;

  const _EmergencyAction({required this.label, required this.number, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.red, size: 28),
        const SizedBox(height: 4),
        Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
