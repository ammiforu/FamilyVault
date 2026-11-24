import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'main_navigation_screen.dart';

class LockScreen extends StatefulWidget {
  final bool isConfigured;
  const LockScreen({super.key, required this.isConfigured});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  String _firstEnteredPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4 || _enteredPin.length == 6) {
        _handleSubmit();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!widget.isConfigured) {
      // First-time setup
      if (!_isConfirming) {
        if (_enteredPin.length < 4) return;
        setState(() {
          _firstEnteredPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstEnteredPin) {
          await StorageService.instance.setupMasterPin(_enteredPin);
          await StorageService.instance.loadVaultBundle();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _enteredPin = '';
            _firstEnteredPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Unlock existing vault
      final isValid = await StorageService.instance.verifyMasterPin(_enteredPin);
      if (isValid) {
        await StorageService.instance.loadVaultBundle();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      } else {
        if (_enteredPin.length >= 4) {
          setState(() {
            _errorMessage = 'Incorrect PIN. Please try again.';
            _enteredPin = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = !widget.isConfigured
        ? (_isConfirming ? 'Confirm Master PIN' : 'Create Master PIN')
        : 'Family Vault Locked';

    final subtitleText = !widget.isConfigured
        ? (_isConfirming ? 'Re-enter your 4-6 digit PIN to confirm' : 'Set a master security PIN for your family')
        : 'Enter your PIN to decrypt and access vault';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titleText,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    border: Border.all(
                      color: isFilled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Spacer(flex: 2),
            // Numeric Keypad
            Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildKeyRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeyRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeyRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Clear or Submit Button
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: IconButton(
                          icon: const Icon(Icons.check_circle_outline, size: 28),
                          onPressed: _enteredPin.length >= 4 ? _handleSubmit : null,
                        ),
                      ),
                      _buildKeyButton('0'),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 28),
                          onPressed: _onBackspace,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKeyButton).toList(),
    );
  }

  Widget _buildKeyButton(String digit) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => _onDigitPressed(digit),
        child: Text(
          digit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
