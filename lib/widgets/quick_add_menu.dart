import 'package:flutter/material.dart';
import '../models/vault_item.dart';
import '../screens/bills_screen.dart';
import '../screens/insurance_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/property_screen.dart';
import '../screens/vehicle_screen.dart';
import '../screens/warranty_screen.dart';
import '../screens/wealth_screen.dart';

class QuickAddMenu {
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick Add to FamilyVault',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose what you want to save — takes just a few seconds',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.15,
                  children: [
                    _tile(ctx, 'bank', 'Bank / Wealth', 'Checking, 401k, Card', Icons.account_balance_rounded, const Color(0xFF10B981)),
                    _tile(ctx, 'property', 'Home / Map Pin', 'Address, Sq Ft, Equity', Icons.pin_drop_rounded, const Color(0xFF8B5CF6)),
                    _tile(ctx, 'insurance', 'Life / LIC / Claim', 'Policy, Agent, Nominee', Icons.health_and_safety_rounded, const Color(0xFF6366F1)),
                    _tile(ctx, 'vehicle', 'Car / Vehicle', 'VIN, Price, Oil, Reg', Icons.directions_car_rounded, const Color(0xFFF59E0B)),
                    _tile(ctx, 'warranty', 'Receipt & Warranty', 'Scan & track expiry', Icons.receipt_long_rounded, const Color(0xFF14B8A6)),
                    _tile(ctx, 'bill', 'Recurring Bill', 'Monthly/Annual bills', Icons.repeat_rounded, const Color(0xFFEC4899)),
                    _tile(ctx, 'document', 'Passport / Will', 'IDs, Visas, Legal', Icons.badge_rounded, const Color(0xFF3B82F6)),
                    _tile(ctx, 'login', 'Login / Wi-Fi', 'Passwords & codes', Icons.lock_rounded, const Color(0xFF0EA5E9)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withAlpha(90)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.medical_services_rounded, size: 18),
                    label: const Text('Add Emergency (ICE) Contact'),
                    onPressed: () => Navigator.of(ctx).pop('emergency'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null || !context.mounted) return false;

    switch (result) {
      case 'bank':
        return await WealthScreen.showAddAccountSheet(context);
      case 'property':
        return await PropertyScreen.showAddPropertySheet(context);
      case 'vehicle':
        return await VehicleScreen.showAddVehicleSheet(context);
      case 'warranty':
        return await WarrantyScreen.showAddWarrantySheet(context);
      case 'insurance':
        return await InsuranceScreen.showAddPolicySheet(context);
      case 'bill':
        return await BillsScreen.showAddBillSheet(context);
      case 'document':
        return await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ItemDetailScreen(initialCategory: VaultCategory.document)),
            ) ??
            false;
      case 'login':
        return await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ItemDetailScreen(initialCategory: VaultCategory.login)),
            ) ??
            false;
      case 'emergency':
        return await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ItemDetailScreen(initialCategory: VaultCategory.emergency)),
            ) ??
            false;
      default:
        return false;
    }
  }

  static Widget _tile(BuildContext ctx, String key, String title, String sub, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(ctx).pop(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                  Text(sub, style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
