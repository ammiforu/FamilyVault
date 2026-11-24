import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showAddMemberDialog([FamilyMember? member]) {
    final isEdit = member != null;
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final roleCtrl = TextEditingController(text: member?.role ?? 'Parent');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Family Member' : 'Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name (e.g. Robert, Sarah, Emma)')),
            const SizedBox(height: 8),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (Parent, Child, Grandparent, Spouse)')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              const uuid = Uuid();
              final updated = FamilyMember(
                id: member?.id ?? uuid.v4(),
                name: nameCtrl.text.trim(),
                role: roleCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );

              if (isEdit) {
                final idx = StorageService.instance.members.indexWhere((m) => m.id == updated.id);
                if (idx != -1) StorageService.instance.members[idx] = updated;
                await StorageService.instance.saveVaultBundle();
              } else {
                await StorageService.instance.addFamilyMember(updated);
              }

              if (mounted) {
                Navigator.of(ctx).pop();
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = StorageService.instance.members;
    final activeId = StorageService.instance.activeMemberId;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people_alt_rounded, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Family Members & Access'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Family Access & Sharing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Switch profiles to view assets assigned to you or shared with the whole family.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Members (${members.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Member'),
                onPressed: () => _showAddMemberDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...members.map((m) {
            final isActive = m.id == activeId;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(80),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Color(m.colorValue),
                  child: Text(
                    m.name.isNotEmpty ? m.name[0] : 'F',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.role, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    if (m.phone.isNotEmpty) Text('📞 ${m.phone}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            StorageService.instance.setActiveMember(m.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Switched active profile to ${m.name}'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: const Text('Switch'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showAddMemberDialog(m),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
