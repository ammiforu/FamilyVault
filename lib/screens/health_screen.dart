import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/health_record.dart';
import '../services/storage_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  static Future<bool> showAddHealthSheet(BuildContext context, [HealthRecord? record]) async {
    final isEdit = record != null;
    final nameCtrl = TextEditingController(text: record?.memberName ?? '');
    final bloodCtrl = TextEditingController(text: record?.bloodGroup ?? 'O+');
    final allergiesCtrl = TextEditingController(text: record?.allergies ?? 'None');
    final medsCtrl = TextEditingController(text: record?.medications ?? 'None');
    final docCtrl = TextEditingController(text: record?.primaryDoctor ?? '');
    final phoneCtrl = TextEditingController(text: record?.doctorPhone ?? '');
    final immCtrl = TextEditingController(text: record?.immunizations ?? '');
    const bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? 'Edit Health Record' : 'Add Family Health Record', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop(false)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Family Member Name *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const Text('Blood Group', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: bloodTypes.map((bt) {
                    return ChoiceChip(
                      label: Text(bt, style: const TextStyle(fontSize: 11)),
                      selected: bloodCtrl.text == bt,
                      onSelected: (_) => setModalState(() => bloodCtrl.text = bt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(controller: allergiesCtrl, decoration: const InputDecoration(labelText: 'Allergies', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: medsCtrl, decoration: const InputDecoration(labelText: 'Current Medications', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Primary Doctor', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Doctor Phone', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: immCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Immunizations / Vaccinations', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.favorite_rounded),
                    label: Text(isEdit ? 'Save Record' : 'Save Health Record', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      const uuid = Uuid();
                      final updated = HealthRecord(
                        id: record?.id ?? uuid.v4(),
                        memberName: nameCtrl.text.trim(),
                        bloodGroup: bloodCtrl.text.trim(),
                        allergies: allergiesCtrl.text.trim(),
                        medications: medsCtrl.text.trim(),
                        primaryDoctor: docCtrl.text.trim(),
                        doctorPhone: phoneCtrl.text.trim(),
                        immunizations: immCtrl.text.trim(),
                      );
                      if (isEdit) {
                        await StorageService.instance.updateHealthRecord(updated);
                      } else {
                        await StorageService.instance.addHealthRecord(updated);
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return saved ?? false;
  }

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final records = StorageService.instance.healthRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 24),
            SizedBox(width: 8),
            Text('Family Health & Vaccines'),
          ],
        ),
      ),
      body: records.isEmpty
          ? const Center(child: Text('No health records added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: records.length,
              itemBuilder: (_, idx) {
                final r = records[idx];
                final hasAllergy = r.allergies.isNotEmpty && r.allergies.toLowerCase() != 'none';
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.redAccent.withAlpha(35),
                              child: Text(r.bloodGroup.isEmpty ? '?' : r.bloodGroup, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(r.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (a) async {
                                if (a == 'edit') {
                                  if (await HealthScreen.showAddHealthSheet(context, r)) setState(() {});
                                } else if (a == 'delete') {
                                  await StorageService.instance.deleteHealthRecord(r.id);
                                  setState(() {});
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        if (hasAllergy)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                            child: Text('⚠️ Allergies: ${r.allergies}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        Text('💊 Medications: ${r.medications}', style: const TextStyle(fontSize: 13)),
                        if (r.immunizations.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('💉 Vaccines: ${r.immunizations}', style: const TextStyle(fontSize: 13)),
                        ],
                        if (r.primaryDoctor.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: Text('🩺 Doctor: ${r.primaryDoctor}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              if (r.doctorPhone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                                  onPressed: () => launchUrl(Uri.parse('tel:${r.doctorPhone}')),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Health Profile'),
        onPressed: () async {
          if (await HealthScreen.showAddHealthSheet(context)) setState(() {});
        },
      ),
    );
  }
}
