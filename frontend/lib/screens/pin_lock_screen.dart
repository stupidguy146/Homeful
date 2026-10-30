import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_lock_scope.dart';
import '../widgets/pin_pad.dart';
import '../i18n/locale_scope.dart';

/// Full-screen lock shown on launch when a PIN is configured. Calls
/// [onUnlocked] once the correct PIN (or biometric) is provided.
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  bool _error = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBiometric());
  }

  Future<void> _maybeBiometric() async {
    final lock = AppLockScope.read(context);
    final can = await lock.canUseBiometrics();
    final enabled = await lock.isBiometricEnabled();
    if (!mounted) return;
    setState(() => _biometricAvailable = can && enabled);
    if (can && enabled) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final lock = AppLockScope.read(context);
    final ok =
        await lock.authenticateBiometric(context.strings.biometricReason);
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _onCompleted(String pin) async {
    final ok = await AppLockScope.read(context).verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xl * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      const Icon(Icons.lock_rounded,
                          size: 56, color: AppColors.brand500),
                      const SizedBox(height: AppSpacing.lg),
                      Text(s.enterPinTitle, style: AppType.headlineMedium),
                      if (_error) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(s.wrongPin,
                            style: AppType.bodyMedium
                                .copyWith(color: AppColors.danger)),
                      ],
                      const Spacer(),
                      PinPad(
                        value: _pin,
                        error: _error,
                        onChanged: (v) => setState(() {
                          _pin = v;
                          _error = false;
                        }),
                        onCompleted: _onCompleted,
                        leadingKey: _biometricAvailable
                            ? const Icon(Icons.fingerprint_rounded,
                                color: AppColors.brand500)
                            : null,
                        onLeadingKey:
                            _biometricAvailable ? _tryBiometric : null,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
