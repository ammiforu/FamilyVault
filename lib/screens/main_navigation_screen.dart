import 'package:flutter/material.dart';
import 'vault_screen.dart';
import 'spreadsheet_screen.dart';
import 'password_generator_screen.dart';
import 'emergency_screen.dart';
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
      const SpreadsheetScreen(),
      const PasswordGeneratorScreen(),
      const EmergencyScreen(),
      SettingsScreen(
        onThemeToggle: widget.onThemeToggle ?? () {},
        isDarkMode: widget.isDarkMode,
      ),
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
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart_rounded),
            label: 'Spreadsheet',
          ),
          NavigationDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.key_rounded),
            label: 'Generator',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Emergency',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
