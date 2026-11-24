import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

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

  void _showAddVehicleDialog([Vehicle? vehicle]) {
    final isEdit = vehicle != null;
    final nickCtrl = TextEditingController(text: vehicle?.nickname ?? '');
    final makeCtrl = TextEditingController(text: vehicle?.make ?? '');
    final modelCtrl = TextEditingController(text: vehicle?.model ?? '');
    final yearCtrl = TextEditingController(text: vehicle?.year.toString() ?? DateTime.now().year.toString());
    final plateCtrl = TextEditingController(text: vehicle?.licensePlate ?? '');
    final vinCtrl = TextEditingController(text: vehicle?.vin ?? '');
    final mileageCtrl = TextEditingController(text: vehicle != null ? vehicle.currentMileage.toString() : '');
    final oilMileageCtrl = TextEditingController(text: vehicle != null && vehicle.oilChangeDueMileage > 0 ? vehicle.oilChangeDueMileage.toString() : '');
    final insuranceCompanyCtrl = TextEditingController(text: vehicle?.insuranceCompany ?? '');
    final insurancePolicyCtrl = TextEditingController(text: vehicle?.insurancePolicyNumber ?? '');
    final valueCtrl = TextEditingController(text: vehicle != null ? vehicle.estimatedValue.toStringAsFixed(0) : '');
    final memberCtrl = TextEditingController(text: vehicle?.assignedMember ?? 'Entire Family');

    DateTime? regExpiry = vehicle?.registrationExpiry;

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
                      isEdit ? 'Edit Vehicle' : 'Add Vehicle / Car',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nickCtrl,
                  decoration: const InputDecoration(labelText: 'Nickname (e.g. Family SUV, Dad\'s EV)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: makeCtrl,
                        decoration: const InputDecoration(labelText: 'Make (Toyota, Tesla, Ford)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: modelCtrl,
                        decoration: const InputDecoration(labelText: 'Model (Civic, Y, F-150)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plateCtrl,
                        decoration: const InputDecoration(labelText: 'License Plate', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: vinCtrl,
                        decoration: const InputDecoration(labelText: 'VIN Number', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: mileageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Current Mileage', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: oilMileageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Next Oil Change (Mi)', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Est. Market Value', prefixText: '\$ ', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: memberCtrl,
                        decoration: const InputDecoration(labelText: 'Driver / Family Member', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: insuranceCompanyCtrl,
                        decoration: const InputDecoration(labelText: 'Insurance Co. (e.g. GEICO, State Farm)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: insurancePolicyCtrl,
                        decoration: const InputDecoration(labelText: 'Policy Number', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(regExpiry != null
                      ? 'Registration Expiry: ${DateFormat.yMMMd().format(regExpiry!)}'
                      : 'Set Registration Expiry Date'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: regExpiry ?? DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => regExpiry = picked);
                      }
                    },
                    child: const Text('Pick Date'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.directions_car_rounded),
                    label: Text(isEdit ? 'Save Vehicle' : 'Add Vehicle to Fleet'),
                    onPressed: () async {
                      if (makeCtrl.text.trim().isEmpty) return;
                      const uuid = Uuid();
                      final updated = Vehicle(
                        id: vehicle?.id ?? uuid.v4(),
                        nickname: nickCtrl.text.trim().isEmpty ? '${makeCtrl.text} ${modelCtrl.text}' : nickCtrl.text.trim(),
                        make: makeCtrl.text.trim(),
                        model: modelCtrl.text.trim(),
                        year: int.tryParse(yearCtrl.text) ?? DateTime.now().year,
                        licensePlate: plateCtrl.text.trim(),
                        vin: vinCtrl.text.trim(),
                        currentMileage: int.tryParse(mileageCtrl.text) ?? 0,
                        oilChangeDueMileage: int.tryParse(oilMileageCtrl.text) ?? 0,
                        registrationExpiry: regExpiry,
                        insuranceCompany: insuranceCompanyCtrl.text.trim(),
                        insurancePolicyNumber: insurancePolicyCtrl.text.trim(),
                        assignedMember: memberCtrl.text.trim(),
                        estimatedValue: double.tryParse(valueCtrl.text) ?? 0.0,
                        logs: vehicle?.logs,
                      );

                      if (isEdit) {
                        await StorageService.instance.updateVehicle(updated);
                      } else {
                        await StorageService.instance.addVehicle(updated);
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

  void _showAddServiceLogDialog(Vehicle vehicle) {
    final typeCtrl = TextEditingController(text: 'Synthetic Oil & Filter Change');
    final mileageCtrl = TextEditingController(text: vehicle.currentMileage.toString());
    final costCtrl = TextEditingController();
    final centerCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Maintenance: ${vehicle.nickname}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Service Type')),
              const SizedBox(height: 8),
              TextField(controller: mileageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mileage at Service')),
              const SizedBox(height: 8),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (\$)', prefixText: '\$ ')),
              const SizedBox(height: 8),
              TextField(controller: centerCtrl, decoration: const InputDecoration(labelText: 'Service Center / Mechanic')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (parts, warranty)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              const uuid = Uuid();
              final log = MaintenanceLog(
                id: uuid.v4(),
                serviceType: typeCtrl.text.trim(),
                date: DateTime.now(),
                mileage: int.tryParse(mileageCtrl.text) ?? vehicle.currentMileage,
                cost: double.tryParse(costCtrl.text) ?? 0.0,
                serviceCenter: centerCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );

              vehicle.logs.insert(0, log);
              // Also update current vehicle mileage and next oil due
              final currentM = int.tryParse(mileageCtrl.text);
              if (currentM != null && currentM > vehicle.currentMileage) {
                vehicle.currentMileage = currentM;
              }
              if (typeCtrl.text.toLowerCase().contains('oil')) {
                vehicle.oilChangeDueMileage = (currentM ?? vehicle.currentMileage) + 5000;
              }
              await StorageService.instance.updateVehicle(vehicle);

              if (mounted) {
                Navigator.of(ctx).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maintenance record added!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = StorageService.instance.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_car_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Vehicle Fleet & Maintenance'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Family Vehicles (${vehicles.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Vehicle'),
                onPressed: () => _showAddVehicleDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (vehicles.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.no_crash_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No vehicles added yet.'),
                      TextButton(onPressed: () => _showAddVehicleDialog(), child: const Text('Add Family Car')),
                    ],
                  ),
                ),
              ),
            )
          else
            ...vehicles.map((v) {
              final daysLeftReg = v.daysUntilRegistrationExpires;
              final regExpiringSoon = daysLeftReg != null && daysLeftReg <= 30;
              final oilDue = v.isOilChangeDue;

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
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_car_filled_rounded, color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text('${v.year} ${v.make} ${v.model}', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(v.estimatedValue),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                _showAddVehicleDialog(v);
                              } else if (action == 'delete') {
                                await StorageService.instance.deleteVehicle(v.id);
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

                      // ALERTS: REGISTRATION OR OIL CHANGE
                      if (regExpiringSoon)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  daysLeftReg < 0
                                      ? '🚨 Registration EXPIRED ${daysLeftReg.abs()} days ago!'
                                      : '⚠️ Vehicle registration expires in $daysLeftReg days!',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (oilDue)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.oil_barrel_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🚨 Oil change service is DUE!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // SPEC DETAILS GRID
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Plate: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(v.licensePlate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 14),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _copy(v.licensePlate, 'License plate'),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text('Mileage: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('${v.currentMileage} mi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            if (v.vin.isNotEmpty)
                              Row(
                                children: [
                                  const Text('VIN: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Expanded(
                                    child: Text(
                                      v.vin,
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _copy(v.vin, 'VIN'),
                                  ),
                                ],
                              ),
                            if (v.oilChangeDueMileage > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Next Oil Change Due:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('${v.oilChangeDueMileage} mi', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                ],
                              ),
                            if (v.insuranceCompany.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Insurance:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('${v.insuranceCompany} (${v.insurancePolicyNumber})', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // MAINTENANCE SERVICE LOGS SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Service Logs (${v.logs.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          TextButton.icon(
                            icon: const Icon(Icons.build_circle_outlined, size: 16),
                            label: const Text('Log Service'),
                            onPressed: () => _showAddServiceLogDialog(v),
                          ),
                        ],
                      ),
                      if (v.logs.isNotEmpty)
                        ...v.logs.map((log) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat.yMMMd().format(log.date)} - ${log.serviceType}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '\$${log.cost.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
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
