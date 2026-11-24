import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/recurring_bill.dart';
import '../services/storage_service.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  static Future<bool> showAddBillSheet(BuildContext context, [RecurringBill? bill]) async {
    final isEdit = bill != null;
    final nameCtrl = TextEditingController(text: bill?.name ?? '');
    final amountCtrl = TextEditingController(text: bill != null ? bill.amount.toStringAsFixed(2) : '');
    final dueDayCtrl = TextEditingController(text: bill?.dueDayOfMonth.toString() ?? '1');
    final notesCtrl = TextEditingController(text: bill?.notes ?? '');
    String selectedCat = bill?.category ?? 'Utilities';
    String selectedFreq = bill?.frequency ?? 'Monthly';
    bool isAutoPay = bill?.isAutoPay ?? true;

    const cats = ['Housing', 'Utilities', 'Subscriptions', 'Insurance', 'Education', 'Other'];

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
                    Text(isEdit ? 'Edit Bill' : 'Add Recurring Bill', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop(false)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cats.map((c) {
                    return ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 11)),
                      selected: selectedCat == c,
                      onSelected: (_) => setModalState(() => selectedCat = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Bill / Subscription Name *', hintText: 'e.g. Electricity, Internet, Mortgage', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: dueDayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Due Day (1-31)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Cycle: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...['Monthly', 'Quarterly', 'Annual'].map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(f, style: const TextStyle(fontSize: 11)),
                          selected: selectedFreq == f,
                          onSelected: (_) => setModalState(() => selectedFreq = f),
                        ),
                      );
                    }),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-Pay Enabled'),
                  value: isAutoPay,
                  onChanged: (v) => setModalState(() => isAutoPay = v),
                ),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (Account #, payment card)', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.repeat_rounded),
                    label: Text(isEdit ? 'Save Bill' : 'Add Recurring Bill', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      const uuid = Uuid();
                      final updated = RecurringBill(
                        id: bill?.id ?? uuid.v4(),
                        name: nameCtrl.text.trim(),
                        category: selectedCat,
                        amount: double.tryParse(amountCtrl.text) ?? 0.0,
                        frequency: selectedFreq,
                        dueDayOfMonth: (int.tryParse(dueDayCtrl.text) ?? 1).clamp(1, 31),
                        isAutoPay: isAutoPay,
                        notes: notesCtrl.text.trim(),
                      );
                      if (isEdit) {
                        await StorageService.instance.updateBill(updated);
                      } else {
                        await StorageService.instance.addBill(updated);
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
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final bills = StorageService.instance.bills;
    final monthlyTotal = bills.fold(0.0, (s, b) => s + b.monthlyEquivalent);
    final annualTotal = monthlyTotal * 12;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.repeat_rounded, color: Colors.orangeAccent, size: 24),
            SizedBox(width: 8),
            Text('Recurring Bills & Subs'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withAlpha(80)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Monthly Burn', style: TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
                    Text(currencyFormat.format(monthlyTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Annual Total', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text(currencyFormat.format(annualTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (bills.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No recurring bills added yet.')))
          else
            ...bills.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withAlpha(30),
                      child: Text('${b.dueDayOfMonth}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                    ),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${b.category} • ${b.frequency} • ${b.isAutoPay ? "Auto-Pay ON" : "Manual Pay"}', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currencyFormat.format(b.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        PopupMenuButton<String>(
                          onSelected: (a) async {
                            if (a == 'edit') {
                              if (await BillsScreen.showAddBillSheet(context, b)) setState(() {});
                            } else if (a == 'delete') {
                              await StorageService.instance.deleteBill(b.id);
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
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
        onPressed: () async {
          if (await BillsScreen.showAddBillSheet(context)) setState(() {});
        },
      ),
    );
  }
}
