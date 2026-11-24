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
    const seedColor = Color(0xFF1E88E5);

    return MaterialApp(
      title: 'FamilyVault',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: LockScreen(isConfigured: widget.isConfigured),
    );
  }
}
