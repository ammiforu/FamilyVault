import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/property_asset.dart';
import '../services/storage_service.dart';

class PropertyScreen extends StatefulWidget {
  const PropertyScreen({super.key});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  Future<void> _openMapPin(PropertyAsset prop) async {
    Uri mapUri;
    if (prop.latitude != null && prop.longitude != null) {
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${prop.latitude},${prop.longitude}');
    } else {
      final encodedAddr = Uri.encodeComponent(prop.fullAddress);
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddr');
    }

    try {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: prop.fullAddress));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address copied to clipboard!'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showAddPropertyDialog([PropertyAsset? prop]) {
    final isEdit = prop != null;
    final titleCtrl = TextEditingController(text: prop?.title ?? '');
    final typeCtrl = TextEditingController(text: prop?.propertyType ?? 'Single Family Home');
    final addressCtrl = TextEditingController(text: prop?.fullAddress ?? '');
    final latCtrl = TextEditingController(text: prop?.latitude?.toString() ?? '');
    final lngCtrl = TextEditingController(text: prop?.longitude?.toString() ?? '');
    final purchaseCtrl = TextEditingController(text: prop != null ? prop.purchasePrice.toStringAsFixed(0) : '');
    final valueCtrl = TextEditingController(text: prop != null ? prop.estimatedMarketValue.toStringAsFixed(0) : '');
    final mortgageCtrl = TextEditingController(text: prop != null ? prop.mortgageRemaining.toStringAsFixed(0) : '');
    final parcelCtrl = TextEditingController(text: prop?.parcelNumber ?? '');
    final notesCtrl = TextEditingController(text: prop?.notes ?? '');
    final memberCtrl = TextEditingController(text: prop?.assignedMember ?? 'Entire Family');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
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
                      isEdit ? 'Edit Property / Land' : 'Add Property or Land',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Property Name (e.g. Primary Home, Farm Land)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Type (Single Family, Condo, 5-Acre Land)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Street Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Latitude (Optional)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Longitude (Optional)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Market Value', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: mortgageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Remaining Mortgage', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: purchaseCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Original Price', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: parcelCtrl,
                        decoration: const InputDecoration(labelText: 'Parcel / Deed #', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memberCtrl,
                  decoration: const InputDecoration(labelText: 'Owner / Family Member', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (Lot size, square feet, title deeds location)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.home_work_rounded),
                    label: Text(isEdit ? 'Save Changes' : 'Add Property Asset'),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      const uuid = Uuid();
                      final updated = PropertyAsset(
                        id: prop?.id ?? uuid.v4(),
                        title: titleCtrl.text.trim(),
                        propertyType: typeCtrl.text.trim(),
                        fullAddress: addressCtrl.text.trim(),
                        latitude: double.tryParse(latCtrl.text),
                        longitude: double.tryParse(lngCtrl.text),
                        purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0.0,
                        estimatedMarketValue: double.tryParse(valueCtrl.text) ?? 0.0,
                        mortgageRemaining: double.tryParse(mortgageCtrl.text) ?? 0.0,
                        parcelNumber: parcelCtrl.text.trim(),
                        assignedMember: memberCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );

                      if (isEdit) {
                        await StorageService.instance.updateProperty(updated);
                      } else {
                        await StorageService.instance.addProperty(updated);
                      }

                      if (mounted) {
                        Navigator.of(ctx).pop();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final properties = StorageService.instance.properties;
    final totalRealEstateValue = properties.fold(0.0, (s, p) => s + p.estimatedMarketValue);
    final totalEquity = properties.fold(0.0, (s, p) => s + p.equity);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_work_rounded, color: Colors.deepPurple, size: 24),
            SizedBox(width: 8),
            Text('Real Estate & Land Assets'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SUMMARY BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepPurple.withAlpha(80)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Real Estate', style: TextStyle(fontSize: 12, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(currencyFormat.format(totalRealEstateValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Container(width: 1, height: 30, color: theme.colorScheme.outlineVariant),
                Column(
                  children: [
                    const Text('Home Equity', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(currencyFormat.format(totalEquity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Properties & Land (${properties.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Property'),
                onPressed: () => _showAddPropertyDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (properties.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.roofing_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No properties or land recorded.'),
                      TextButton(onPressed: () => _showAddPropertyDialog(), child: const Text('Add First Property')),
                    ],
                  ),
                ),
              ),
            )
          else
            ...properties.map((p) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.home_rounded, color: Colors.deepPurple, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text(p.propertyType, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                _showAddPropertyDialog(p);
                              } else if (action == 'delete') {
                                await StorageService.instance.deleteProperty(p.id);
                                setState(() {});
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // MAP ADDRESS PINNING BUTTON / CARD
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: Colors.red, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.fullAddress,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  if (p.latitude != null && p.longitude != null)
                                    Text(
                                      'GPS: ${p.latitude!.toStringAsFixed(4)}, ${p.longitude!.toStringAsFixed(4)}',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                    ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const Text('Map Pin'),
                              onPressed: () => _openMapPin(p),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // FINANCIAL DETAILS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Est. Value', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(currencyFormat.format(p.estimatedMarketValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mortgage Debt', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(currencyFormat.format(p.mortgageRemaining), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Home Equity', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(currencyFormat.format(p.equity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),

                      if (p.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          p.notes,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
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
