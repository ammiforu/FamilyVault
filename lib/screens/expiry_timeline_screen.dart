import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class ExpiryTimelineScreen extends StatelessWidget {
  const ExpiryTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expiries = StorageService.instance.getUnifiedExpiries();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hourglass_bottom_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Unified Expiry Timeline'),
          ],
        ),
      ),
      body: expiries.isEmpty
          ? const Center(child: Text('No upcoming expirations or renewals recorded.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expiries.length,
              itemBuilder: (_, idx) {
                final item = expiries[idx];
                Color color = Colors.green;
                String badge = '${item.daysLeft}d left';
                if (item.daysLeft < 0) {
                  color = Colors.red;
                  badge = 'EXPIRED';
                } else if (item.daysLeft <= 30) {
                  color = Colors.orange;
                  badge = '${item.daysLeft}d left';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.category} • ${item.subtitle}', style: const TextStyle(fontSize: 12)),
                    trailing: Text(DateFormat.yMMMd().format(item.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                );
              },
            ),
    );
  }
}
