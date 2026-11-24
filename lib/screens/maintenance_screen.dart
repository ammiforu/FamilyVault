import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/home_maintenance_task.dart';
import '../services/storage_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  static Future<bool> showAddTaskSheet(BuildContext context, [HomeMaintenanceTask? task]) async {
    final isEdit = task != null;
    final nameCtrl = TextEditingController(text: task?.taskName ?? '');
    String selectedArea = task?.area ?? 'HVAC';
    int interval = task?.intervalMonths ?? 3;
    const areas = ['HVAC', 'Safety', 'Plumbing', 'Roof', 'Yard', 'Appliances'];

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Task' : 'Add Home Care Task', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop(false)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: areas.map((a) => ChoiceChip(
                  label: Text(a, style: const TextStyle(fontSize: 11)),
                  selected: selectedArea == a,
                  onSelected: (_) => setModalState(() => selectedArea = a),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Task Name * (e.g. Replace HVAC Filter)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Repeat Every: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ...[1, 3, 6, 12].map((m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('$m mo', style: const TextStyle(fontSize: 11)),
                      selected: interval == m,
                      onSelected: (_) => setModalState(() => interval = m),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.build_rounded),
                  label: Text(isEdit ? 'Save Task' : 'Add Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    const uuid = Uuid();
                    final updated = HomeMaintenanceTask(
                      id: task?.id ?? uuid.v4(),
                      taskName: nameCtrl.text.trim(),
                      area: selectedArea,
                      intervalMonths: interval,
                      lastCompletedDate: task?.lastCompletedDate ?? DateTime.now(),
                    );
                    if (isEdit) {
                      await StorageService.instance.updateMaintenanceTask(updated);
                    } else {
                      await StorageService.instance.addMaintenanceTask(updated);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return saved ?? false;
  }

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  Widget build(BuildContext context) {
    final tasks = StorageService.instance.maintenanceTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.handyman_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Home Care Schedule'),
          ],
        ),
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No home maintenance tasks added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: tasks.length,
              itemBuilder: (_, idx) {
                final t = tasks[idx];
                final days = t.daysUntilDue;
                final urgent = days <= 14;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: (urgent ? Colors.red : Colors.green).withAlpha(30),
                      child: Icon(Icons.home_repair_service_rounded, color: urgent ? Colors.redAccent : Colors.green),
                    ),
                    title: Text(t.taskName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${t.area} • Every ${t.intervalMonths} mo\n${days <= 0 ? "🚨 Due now!" : "Due in $days days (${DateFormat.yMMMd().format(t.nextDueDate)})"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () async {
                        await StorageService.instance.markMaintenanceDone(t.id);
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✓ Marked "${t.taskName}" done! Next reminder reset.'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      child: const Text('Done'),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Home Task'),
        onPressed: () async {
          if (await MaintenanceScreen.showAddTaskSheet(context)) setState(() {});
        },
      ),
    );
  }
}
