import 'package:flutter/material.dart';
import 'vault_screen.dart';
import 'wealth_screen.dart';
import 'vehicle_screen.dart';
import 'property_screen.dart';
import 'warranty_screen.dart';
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
    this.isDarkMode = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
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
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Vault & IDs',
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
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work_rounded),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More Hub',
          ),
        ],
      ),
    );
  }

  Widget _buildMoreHubScreen() {
    final theme = Theme.of(context);

    final hubItems = [
      _HubItem(
        title: 'Receipts & Warranties',
        subtitle: 'Track purchase dates, warranty expiries, and serial #s',
        icon: Icons.receipt_long_rounded,
        color: Colors.teal,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarrantyScreen())),
      ),
      _HubItem(
        title: 'Spreadsheet Grid View',
        subtitle: 'Google Sheets table view with instant CSV import/export',
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
        title: 'Vault Security Settings',
        subtitle: 'Change Master PIN, lock immediately, preferences',
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
            Text('Family Life Tools & Hub'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Specialized Family Modules',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...hubItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
              ),
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
