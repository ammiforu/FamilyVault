import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';
import 'vault_screen.dart';
import 'wealth_screen.dart';
import 'vehicle_screen.dart';
import 'property_screen.dart';
import 'warranty_screen.dart';
import 'insurance_screen.dart';
import 'bills_screen.dart';
import 'health_screen.dart';
import 'maintenance_screen.dart';
import 'expiry_timeline_screen.dart';
import 'spreadsheet_screen.dart';
import 'profile_screen.dart';
import 'backup_screen.dart';
import 'emergency_screen.dart';
import 'password_generator_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final bool isDarkMode;

  const MainNavigationScreen({
    super.key,
    this.onThemeToggle,
    this.isDarkMode = true,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _navigateToTab),
      const VaultScreen(),
      const WealthScreen(),
      const VehicleScreen(),
      const PropertyScreen(),
      _buildMoreHubScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wealth',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildMoreHubScreen() {
    final theme = Theme.of(context);

    final hubItems = [
      _HubItem(
        title: 'Insurance, LIC & Claims',
        subtitle: 'Life/LIC bonds, nominees, agent contacts & claim docs',
        icon: Icons.health_and_safety_rounded,
        color: Colors.indigoAccent,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InsuranceScreen())),
      ),
      _HubItem(
        title: 'Recurring Bills & Subs',
        subtitle: 'Monthly burn rate, due dates & auto-pay tracker',
        icon: Icons.repeat_rounded,
        color: Colors.pinkAccent,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BillsScreen())),
      ),
      _HubItem(
        title: 'Family Health & Vaccines',
        subtitle: 'Blood groups, allergies, medications & doctor contacts',
        icon: Icons.favorite_rounded,
        color: Colors.redAccent,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthScreen())),
      ),
      _HubItem(
        title: 'Home Care Schedule',
        subtitle: 'HVAC filters, smoke alarms & seasonal maintenance',
        icon: Icons.handyman_rounded,
        color: Colors.amber,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
      ),
      _HubItem(
        title: 'Unified Expiry Timeline',
        subtitle: 'All upcoming renewals & expirations sorted soonest',
        icon: Icons.hourglass_bottom_rounded,
        color: Colors.deepOrangeAccent,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpiryTimelineScreen())),
      ),
      _HubItem(
        title: 'Receipts & Warranties',
        subtitle: 'Attach receipt photos, track warranty expiries & serial #s',
        icon: Icons.receipt_long_rounded,
        color: Colors.teal,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarrantyScreen())),
      ),
      _HubItem(
        title: 'Google Sheets & Grid View',
        subtitle: 'Sync live Google Sheets URL or import/export CSV',
        icon: Icons.table_chart_rounded,
        color: Colors.green,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpreadsheetScreen())),
      ),
      _HubItem(
        title: 'Family Profiles & Sharing',
        subtitle: 'Switch users: Dad, Mom, Children, Dependents',
        icon: Icons.people_alt_rounded,
        color: Colors.blue,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      _HubItem(
        title: 'Cloud Backup & Privacy',
        subtitle: 'Export encrypted bundles to Google Drive, iCloud, or local file',
        icon: Icons.cloud_sync_rounded,
        color: Colors.indigo,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
      ),
      _HubItem(
        title: 'Emergency ICE Hub',
        subtitle: 'Doctors, medical allergies, blood types, emergency dial',
        icon: Icons.medical_services_rounded,
        color: Colors.red,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyScreen())),
      ),
      _HubItem(
        title: 'Password Generator',
        subtitle: 'Generate ultra-strong randomized passwords & keys',
        icon: Icons.key_rounded,
        color: Colors.amber.shade800,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PasswordGeneratorScreen())),
      ),
      _HubItem(
        title: 'Vault Security & Reset',
        subtitle: 'Change Master PIN, clear sample data, lock immediately',
        icon: Icons.settings_rounded,
        color: Colors.blueGrey,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SettingsScreen(
            onThemeToggle: widget.onThemeToggle ?? () {},
            isDarkMode: widget.isDarkMode,
          ),
        )),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_rounded, size: 24),
            SizedBox(width: 8),
            Text('Family Tools & Hub'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'All Family Modules',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...hubItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(item.subtitle, style: theme.textTheme.bodySmall),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: item.onTap,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
