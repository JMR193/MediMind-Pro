import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../core/theme.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isUnlocked = false;
  String _pinEntered = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  void _checkLock() async {
    final repo = context.read<MedicationRepository>();
    if (!repo.settings.appLockEnabled) {
      setState(() => _isUnlocked = true);
      return;
    }

    if (repo.settings.biometricEnabled) {
      _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return;

      final didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate to access your MediMind medical records',
      );

      if (didAuth) {
        setState(() => _isUnlocked = true);
      }
    } catch (_) {}
  }

  void _onDigit(String digit) {
    if (_pinEntered.length < 4) {
      setState(() {
        _pinEntered += digit;
        _errorMessage = null;
      });

      if (_pinEntered.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_pinEntered.isNotEmpty) {
      setState(() {
        _pinEntered = _pinEntered.substring(0, _pinEntered.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final repo = context.read<MedicationRepository>();
    final targetPin = repo.settings.appPin ?? '1234';

    if (_pinEntered == targetPin) {
      setState(() => _isUnlocked = true);
    } else {
      setState(() {
        _pinEntered = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    if (!repo.settings.appLockEnabled || _isUnlocked) {
      return widget.child;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text('MediMind Pro Locked', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Confidential Medical Data Protected',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pinEntered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: filled ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: MediMindTheme.alertRed, fontSize: 13)),
              ],
              const SizedBox(height: 36),
              // Numeric Keypad
              _buildKeypad(),
              const SizedBox(height: 20),
              if (repo.settings.biometricEnabled)
                TextButton.icon(
                  onPressed: _authenticateBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Fingerprint / Face ID'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del']
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 72, height: 72);
                if (key == 'del') {
                  return SizedBox(
                    width: 72,
                    height: 72,
                    child: IconButton(
                      onPressed: _onDelete,
                      icon: const Icon(Icons.backspace_outlined),
                    ),
                  );
                }
                return SizedBox(
                  width: 72,
                  height: 72,
                  child: OutlinedButton(
                    onPressed: () => _onDigit(key),
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
