import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/warranty_receipt.dart';
import '../services/storage_service.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  static Future<bool> showAddWarrantySheet(BuildContext context, [WarrantyReceipt? warranty]) async {
    final isEdit = warranty != null;
    final nameCtrl = TextEditingController(text: warranty?.itemName ?? '');
    final catCtrl = TextEditingController(text: warranty?.category ?? 'Electronics');
    final storeCtrl = TextEditingController(text: warranty?.storeMerchant ?? '');
    final priceCtrl = TextEditingController(text: warranty != null ? warranty.price.toStringAsFixed(2) : '');
    final monthsCtrl = TextEditingController(text: warranty?.warrantyPeriodMonths.toString() ?? '12');
    final serialCtrl = TextEditingController(text: warranty?.serialNumber ?? '');
    final receiptCtrl = TextEditingController(text: warranty?.receiptNumber ?? '');
    final memberCtrl = TextEditingController(text: warranty?.assignedMember ?? 'Entire Family');
    final notesCtrl = TextEditingController(text: warranty?.notes ?? '');

    DateTime purchaseDate = warranty?.purchaseDate ?? DateTime.now();
    String imagePath = warranty?.imagePath ?? '';
    final picker = ImagePicker();
    const popularStores = ['Amazon', 'Best Buy', 'Apple', 'Costco', 'Home Depot', 'Target', 'Walmart'];

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
                    Text(
                      isEdit ? 'Edit Receipt & Warranty' : 'Add Receipt & Warranty',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop(false)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product / Item Name *', hintText: 'e.g. 65" TV, Laptop, Washer', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: popularStores.map((s) {
                    return ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      selected: storeCtrl.text.trim().toLowerCase() == s.toLowerCase(),
                      onSelected: (_) => setModalState(() => storeCtrl.text = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: storeCtrl,
                        decoration: const InputDecoration(labelText: 'Store / Merchant', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Price Paid', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Warranty: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    ...[12, 24, 36, 60].map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${m ~/ 12} yr', style: const TextStyle(fontSize: 11)),
                          selected: monthsCtrl.text == m.toString(),
                          onSelected: (_) => setModalState(() => monthsCtrl.text = m.toString()),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Scan Receipt'),
                        onPressed: () async {
                          final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                          if (file != null) setModalState(() => imagePath = file.path);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('From Gallery'),
                        onPressed: () async {
                          final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (file != null) setModalState(() => imagePath = file.path);
                        },
                      ),
                    ),
                  ],
                ),
                if (imagePath.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(imagePath, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Text('Receipt photo attached'))
                        : Image.file(File(imagePath), height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Text('Receipt photo attached')),
                  ),
                ],
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Optional Serial #, Date & Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Serial Number', border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: receiptCtrl, decoration: const InputDecoration(labelText: 'Order / Receipt #', border: OutlineInputBorder()))),
                      ],
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded, color: Colors.blue),
                      title: Text('Purchased: ${DateFormat.yMMMd().format(purchaseDate)}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: purchaseDate,
                            firstDate: DateTime(2015),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setModalState(() => purchaseDate = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    TextField(controller: memberCtrl, decoration: const InputDecoration(labelText: 'Family Member', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: Text(isEdit ? 'Save Changes' : 'Save Receipt & Warranty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      const uuid = Uuid();
                      final updated = WarrantyReceipt(
                        id: warranty?.id ?? uuid.v4(),
                        itemName: nameCtrl.text.trim(),
                        category: catCtrl.text.trim(),
                        storeMerchant: storeCtrl.text.trim().isEmpty ? 'Store' : storeCtrl.text.trim(),
                        purchaseDate: purchaseDate,
                        price: double.tryParse(priceCtrl.text) ?? 0.0,
                        warrantyPeriodMonths: int.tryParse(monthsCtrl.text) ?? 12,
                        serialNumber: serialCtrl.text.trim(),
                        receiptNumber: receiptCtrl.text.trim(),
                        assignedMember: memberCtrl.text.trim().isEmpty ? 'Entire Family' : memberCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                        imagePath: imagePath,
                      );

                      if (isEdit) {
                        await StorageService.instance.updateWarranty(updated);
                      } else {
                        await StorageService.instance.addWarranty(updated);
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
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  String _searchQuery = '';

  void _copy(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!'), behavior: SnackBarBehavior.floating),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warranties = StorageService.instance.warranties.where((w) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return w.itemName.toLowerCase().contains(q) ||
          w.storeMerchant.toLowerCase().contains(q) ||
          w.serialNumber.toLowerCase().contains(q) ||
          w.category.toLowerCase().contains(q);
    }).toList();

    final activeCount = warranties.where((w) => !w.isExpired).length;
    final totalInsuredValue = warranties.fold(0.0, (s, w) => s + w.price);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.teal, size: 24),
            SizedBox(width: 8),
            Text('Receipts & Warranties'),
          ],
        ),
      ),
      body: Column(
        children: [
          // SUMMARY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Active Warranties', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('$activeCount Active', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Container(width: 1, height: 30, color: theme.colorScheme.outlineVariant),
                  Column(
                    children: [
                      const Text('Total Covered Value', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(currencyFormat.format(totalInsuredValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search receipts, serial numbers, stores...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 8),

          // LIST
          Expanded(
            child: warranties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No receipts found.'),
                        TextButton(
                          onPressed: () async {
                            if (await WarrantyScreen.showAddWarrantySheet(context)) setState(() {});
                          },
                          child: const Text('Add Product Receipt'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: warranties.length,
                    itemBuilder: (ctx, index) {
                      final item = warranties[index];
                      final isExpired = item.isExpired;
                      final daysLeft = item.daysUntilWarrantyExpires;

                      Color badgeColor = Colors.green;
                      String badgeText = '$daysLeft days left';
                      if (isExpired) {
                        badgeColor = Colors.red;
                        badgeText = 'Expired';
                      } else if (daysLeft <= 30) {
                        badgeColor = Colors.orange;
                        badgeText = 'Expires soon ($daysLeft d)';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: Colors.teal, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('${item.storeMerchant} • ${item.category}', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(item.price),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Purchased: ${DateFormat.yMMMd().format(item.purchaseDate)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    'Expiry: ${DateFormat.yMMMd().format(item.warrantyExpiryDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isExpired ? Colors.red : null,
                                    ),
                                  ),
                                ],
                              ),

                              if (item.serialNumber.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Text('S/N: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(item.serialNumber, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 14),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _copy(item.serialNumber, 'Serial number'),
                                    ),
                                  ],
                                ),
                              ],

                              if (item.notes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.notes,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit'),
                                    onPressed: () async {
                                      if (await WarrantyScreen.showAddWarrantySheet(context, item)) setState(() {});
                                    },
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    onPressed: () async {
                                      await StorageService.instance.deleteWarranty(item.id);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Receipt'),
        onPressed: () async {
          if (await WarrantyScreen.showAddWarrantySheet(context)) setState(() {});
        },
      ),
    );
  }
}
