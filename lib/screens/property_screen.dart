import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/property_asset.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PropertyScreen extends StatefulWidget {
  const PropertyScreen({super.key});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  final MapController _mainMapController = MapController();
  bool _showMap = true;

  Future<void> _openExternalMapPin(PropertyAsset prop) async {
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

  void _focusPropertyOnMap(PropertyAsset prop) {
    if (prop.latitude != null && prop.longitude != null) {
      setState(() => _showMap = true);
      _mainMapController.move(LatLng(prop.latitude!, prop.longitude!), 14.0);
    } else {
      _openExternalMapPin(prop);
    }
  }

  void _showAddPropertyDialog([PropertyAsset? prop]) {
    final isEdit = prop != null;
    final titleCtrl = TextEditingController(text: prop?.title ?? '');
    final typeCtrl = TextEditingController(text: prop?.propertyType ?? 'Single Family Home');
    final addressCtrl = TextEditingController(text: prop?.fullAddress ?? '');
    final purchaseCtrl = TextEditingController(text: prop != null ? prop.purchasePrice.toStringAsFixed(0) : '');
    final valueCtrl = TextEditingController(text: prop != null ? prop.estimatedMarketValue.toStringAsFixed(0) : '');
    final mortgageCtrl = TextEditingController(text: prop != null ? prop.mortgageRemaining.toStringAsFixed(0) : '');
    final parcelCtrl = TextEditingController(text: prop?.parcelNumber ?? '');
    final notesCtrl = TextEditingController(text: prop?.notes ?? '');
    final memberCtrl = TextEditingController(text: prop?.assignedMember ?? 'Entire Family');

    double? selectedLat = prop?.latitude ?? 30.2672;
    double? selectedLng = prop?.longitude ?? -97.7431;
    bool hasPickedLocation = prop?.latitude != null && prop?.longitude != null;

    List<AddressSuggestion> suggestions = [];
    bool isSearching = false;
    Timer? debounce;
    final pickerMapController = MapController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void onAddressChanged(String query) {
            debounce?.cancel();
            if (query.trim().length < 3) {
              setModalState(() {
                suggestions = [];
                isSearching = false;
              });
              return;
            }
            setModalState(() => isSearching = true);
            debounce = Timer(const Duration(milliseconds: 450), () async {
              final results = await ApiService.instance.searchAddresses(query);
              if (ctx.mounted) {
                setModalState(() {
                  suggestions = results;
                  isSearching = false;
                });
              }
            });
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.6,
            builder: (ctx, scrollCtrl) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Property / Land' : 'Add & Pin Property',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ADDRESS AUTOCOMPLETE SEARCH FIELD
                  TextField(
                    controller: addressCtrl,
                    onChanged: onAddressChanged,
                    decoration: InputDecoration(
                      labelText: 'Search Address (Live Autocomplete) *',
                      hintText: 'Start typing street, city, or zip...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: const OutlineInputBorder(),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : (addressCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    addressCtrl.clear();
                                    setModalState(() => suggestions = []);
                                  },
                                )
                              : null),
                    ),
                  ),

                  // SUGGESTIONS DROPDOWN LIST
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(ctx).colorScheme.primary.withAlpha(100)),
                      ),
                      child: Column(
                        children: suggestions.map((s) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                            title: Text(s.displayName, style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              setModalState(() {
                                addressCtrl.text = s.displayName;
                                selectedLat = s.latitude;
                                selectedLng = s.longitude;
                                hasPickedLocation = true;
                                suggestions = [];
                              });
                              pickerMapController.move(LatLng(s.latitude, s.longitude), 15.0);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // INTERACTIVE MINI-MAP (TAP TO DROP PIN!)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Interactive Map Pin (Tap anywhere to pin)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          if (hasPickedLocation)
                            Text(
                              '${selectedLat!.toStringAsFixed(4)}, ${selectedLng!.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          child: FlutterMap(
                            mapController: pickerMapController,
                            options: MapOptions(
                              initialCenter: LatLng(selectedLat!, selectedLng!),
                              initialZoom: hasPickedLocation ? 14.0 : 4.0,
                              onTap: (tapPosition, point) async {
                                setModalState(() {
                                  selectedLat = point.latitude;
                                  selectedLng = point.longitude;
                                  hasPickedLocation = true;
                                });
                                final resolved = await ApiService.instance.reverseGeocode(point.latitude, point.longitude);
                                if (ctx.mounted) {
                                  setModalState(() {
                                    addressCtrl.text = resolved;
                                  });
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.familyvault.app.family_vault',
                              ),
                              if (hasPickedLocation)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(selectedLat!, selectedLng!),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Property Name (e.g. Primary Home, Farm Land) *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: 'Type (Single Family, Condo, 5-Acre Land)', border: OutlineInputBorder()),
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
                    decoration: const InputDecoration(labelText: 'Notes (Lot size, sq ft, title deed location)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.pin_drop_rounded),
                      label: Text(isEdit ? 'Save Property Changes' : 'Save & Pin Property'),
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty && addressCtrl.text.trim().isEmpty) return;
                        const uuid = Uuid();
                        final updated = PropertyAsset(
                          id: prop?.id ?? uuid.v4(),
                          title: titleCtrl.text.trim().isEmpty ? addressCtrl.text.split(',').first : titleCtrl.text.trim(),
                          propertyType: typeCtrl.text.trim(),
                          fullAddress: addressCtrl.text.trim(),
                          latitude: hasPickedLocation ? selectedLat : null,
                          longitude: hasPickedLocation ? selectedLng : null,
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
                          if (updated.latitude != null && updated.longitude != null) {
                            _mainMapController.move(LatLng(updated.latitude!, updated.longitude!), 13.0);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final properties = StorageService.instance.properties;
    final totalRealEstateValue = properties.fold(0.0, (s, p) => s + p.estimatedMarketValue);
    final totalEquity = properties.fold(0.0, (s, p) => s + p.equity);

    final pinnedProperties = properties.where((p) => p.latitude != null && p.longitude != null).toList();
    final initialCenter = pinnedProperties.isNotEmpty
        ? LatLng(pinnedProperties.first.latitude!, pinnedProperties.first.longitude!)
        : const LatLng(39.8283, -98.5795);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map_rounded, color: Colors.deepPurpleAccent, size: 24),
            SizedBox(width: 8),
            Text('Properties & Map'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _showMap ? 'Hide Map' : 'Show Map',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LIVE EMBEDDED INTERACTIVE MAP OF ALL PINNED PROPERTIES
          if (_showMap) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 230,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mainMapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: pinnedProperties.isNotEmpty ? 10.5 : 3.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.familyvault.app.family_vault',
                        ),
                        MarkerLayer(
                          markers: pinnedProperties.map((p) {
                            return Marker(
                              point: LatLng(p.latitude!, p.longitude!),
                              width: 120,
                              height: 60,
                              child: GestureDetector(
                                onTap: () => _showAddPropertyDialog(p),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.deepPurpleAccent),
                                      ),
                                      child: Text(
                                        p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Icon(Icons.location_pin, color: Colors.redAccent, size: 32),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(170),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${pinnedProperties.length} Pinned on Map',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                    const Text('Total Real Estate', style: TextStyle(fontSize: 12, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w600)),
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
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Pin Address'),
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
                      const Text('No properties or land recorded yet.'),
                      TextButton(onPressed: () => _showAddPropertyDialog(), child: const Text('Search & Pin First Address')),
                    ],
                  ),
                ),
              ),
            )
          else
            ...properties.map((p) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
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
                            child: const Icon(Icons.home_rounded, color: Colors.deepPurpleAccent, size: 24),
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

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.fullAddress.isEmpty ? 'No address set' : p.fullAddress,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  if (p.latitude != null && p.longitude != null)
                                    Text(
                                      'Pinned: ${p.latitude!.toStringAsFixed(4)}, ${p.longitude!.toStringAsFixed(4)}',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.green),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Focus on In-App Map',
                              icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                              onPressed: () => _focusPropertyOnMap(p),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.directions_rounded, size: 16),
                              label: const Text('Navigate'),
                              onPressed: () => _openExternalMapPin(p),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

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
                              Text(currencyFormat.format(p.mortgageRemaining), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent)),
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
