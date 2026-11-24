import 'package:flutter/material.dart';
import 'screens/lock_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isConfigured = await StorageService.instance.isVaultConfigured();

  runApp(FamilyVaultApp(isConfigured: isConfigured));
}

class FamilyVaultApp extends StatefulWidget {
  final bool isConfigured;
  const FamilyVaultApp({super.key, required this.isConfigured});

  @override
  State<FamilyVaultApp> createState() => _FamilyVaultAppState();
}

class _FamilyVaultAppState extends State<FamilyVaultApp> {
  final ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    const primaryAccent = Color(0xFF6366F1); // Modern Indigo
    const secondaryAccent = Color(0xFF10B981); // Emerald

    return MaterialApp(
      title: 'FamilyVault',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccent,
          secondary: secondaryAccent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccent,
          secondary: secondaryAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withAlpha(18)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          indicatorColor: primaryAccent.withAlpha(50),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF0F172A),
        ),
      ),
      home: LockScreen(isConfigured: widget.isConfigured),
    );
  }
}
