import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  double _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const numbers = '23456789';
    const symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    String charPool = '';
    if (_includeUppercase) charPool += upper;
    if (_includeLowercase) charPool += lower;
    if (_includeNumbers) charPool += numbers;
    if (_includeSymbols) charPool += symbols;

    if (charPool.isEmpty) {
      setState(() => _generatedPassword = 'Select at least one option');
      return;
    }

    final rand = Random.secure();
    final pwd = List.generate(_length.round(), (index) => charPool[rand.nextInt(charPool.length)]).join();
    setState(() => _generatedPassword = pwd);
  }

  void _copyToClipboard() {
    if (_generatedPassword.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _calculateStrength() {
    if (_generatedPassword.isEmpty) return 0.0;
    double score = 0;
    if (_length >= 12) score += 0.3;
    if (_length >= 16) score += 0.2;
    if (_includeUppercase) score += 0.15;
    if (_includeLowercase) score += 0.15;
    if (_includeNumbers) score += 0.1;
    if (_includeSymbols) score += 0.1;
    return score.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.4) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthLabel(double strength) {
    if (strength < 0.4) return 'Weak';
    if (strength < 0.7) return 'Medium Strength';
    return 'Strong & Secure';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _calculateStrength();
    final strengthColor = _getStrengthColor(strength);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.key_rounded, size: 22),
            SizedBox(width: 8),
            Text('Password Generator'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Display Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                SelectableText(
                  _generatedPassword,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStrengthLabel(strength),
                  style: TextStyle(
                    color: strengthColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Password'),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Generate New',
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Length Slider
          Text(
            'Password Length: ${_length.round()} characters',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _length,
            min: 8,
            max: 32,
            divisions: 24,
            label: '${_length.round()}',
            onChanged: (val) {
              setState(() => _length = val);
              _generatePassword();
            },
          ),
          const SizedBox(height: 16),

          // Options
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Uppercase Letters (A-Z)'),
                  value: _includeUppercase,
                  onChanged: (val) {
                    setState(() => _includeUppercase = val);
                    _generatePassword();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Lowercase Letters (a-z)'),
                  value: _includeLowercase,
                  onChanged: (val) {
                    setState(() => _includeLowercase = val);
                    _generatePassword();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Numbers (0-9)'),
                  value: _includeNumbers,
                  onChanged: (val) {
                    setState(() => _includeNumbers = val);
                    _generatePassword();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Special Symbols (!@#\$%^&*)'),
                  value: _includeSymbols,
                  onChanged: (val) {
                    setState(() => _includeSymbols = val);
                    _generatePassword();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
