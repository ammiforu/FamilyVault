import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import 'emergency_screen.dart';
import 'profile_screen.dart';
import 'spreadsheet_screen.dart';
import 'warranty_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeDashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  Future<void> _confirmClearSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Fresh with Your Own Data?'),
        content: const Text(
          'This will remove all pre-loaded sample accounts, vehicles, properties, and receipts so you can enter your real family records.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep Sample')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All Sample Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.clearAllDataAndStartFresh();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Vault cleared! Ready for your real family data.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = StorageService.instance;
    final activeMember = storage.activeMember;
    final alerts = storage.getUpcomingAlerts();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // TOP GREETING + PROFILE SWITCHER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FamilyVault OS',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Active: ${activeMember?.name ?? "My Family"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(activeMember?.colorValue ?? 0xFF6366F1),
                            child: Text(
                              (activeMember?.name.isNotEmpty ?? false) ? activeMember!.name[0] : 'F',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SAMPLE DATA BANNER (if active)
              if (storage.isSampleData)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(28),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Viewing sample demo data. Clear it anytime to add your real family records.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _confirmClearSampleData,
                        child: const Text('Clear Demo', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // HERO NET WORTH CARD
              GestureDetector(
                onTap: () => widget.onNavigateTab(2),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withAlpha(60),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'FAMILY NET WORTH',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Local Encrypted', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(storage.netWorth),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _heroMetric(
                              'Total Assets',
                              currencyFormat.format(storage.totalAssets),
                              Icons.arrow_upward_rounded,
                              const Color(0xFF6EE7B7),
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _heroMetric(
                              'Total Debts',
                              currencyFormat.format(storage.totalLiabilities),
                              Icons.arrow_downward_rounded,
                              const Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // QUICK ACTIONS GRID
              const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  _quickTile('Map & Homes', Icons.map_rounded, const Color(0xFF8B5CF6), () => widget.onNavigateTab(4)),
                  _quickTile('Vehicles', Icons.directions_car_rounded, const Color(0xFFF59E0B), () => widget.onNavigateTab(3)),
                  _quickTile('Receipts', Icons.receipt_long_rounded, const Color(0xFF14B8A6), () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarrantyScreen()));
                    setState(() {});
                  }),
                  _quickTile('Sheets Sync', Icons.table_chart_rounded, const Color(0xFF22C55E), () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpreadsheetScreen()));
                    setState(() {});
                  }),
                  _quickTile('Bank / Wealth', Icons.account_balance_rounded, const Color(0xFF3B82F6), () => widget.onNavigateTab(2)),
                  _quickTile('Emergency ICE', Icons.medical_services_rounded, const Color(0xFFEF4444), () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyScreen()));
                    setState(() {});
                  }),
                ],
              ),
              const SizedBox(height: 22),

              // UPCOMING ALERTS & REMINDERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Alerts (${alerts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (alerts.isNotEmpty)
                    const Text('Tap to view', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),
              if (alerts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All caught up! No urgent renewals, oil changes, or warranty expirations.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...alerts.map((a) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (a.isUrgent ? Colors.red : Colors.amber).withAlpha(30),
                        child: Icon(
                          a.isUrgent ? Icons.priority_high_rounded : Icons.notifications_active_rounded,
                          color: a.isUrgent ? Colors.red : Colors.amber,
                          size: 20,
                        ),
                      ),
                      title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(a.subtitle, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        if (a.tabIndex == 5) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarrantyScreen()));
                        } else {
                          widget.onNavigateTab(a.tabIndex);
                        }
                      },
                    ),
                  );
                }),

              const SizedBox(height: 18),

              // OVERVIEW COUNTS
              const Text('Your Family Vault at a Glance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBadge('${storage.items.length}', 'Docs & IDs', () => widget.onNavigateTab(1)),
                      _statBadge('${storage.wealthAccounts.length}', 'Accounts', () => widget.onNavigateTab(2)),
                      _statBadge('${storage.vehicles.length}', 'Vehicles', () => widget.onNavigateTab(3)),
                      _statBadge('${storage.properties.length}', 'Properties', () => widget.onNavigateTab(4)),
                      _statBadge('${storage.warranties.length}', 'Warranties', () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarrantyScreen()));
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMetric(String label, String val, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _quickTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String count, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
