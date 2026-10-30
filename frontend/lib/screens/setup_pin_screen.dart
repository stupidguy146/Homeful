import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_lock_scope.dart';
import '../widgets/pin_pad.dart';
import '../i18n/locale_scope.dart';
import 'main_shell.dart';

/// Post-registration: create a 6-digit PIN (enter + confirm), then optionally
/// enable biometric unlock. PIN is stored hashed locally; nothing leaves the
/// device. Finishing enters the app ([MainShell]).
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

enum _Step { enter, confirm, biometric }

class _SetupPinScreenState extends State<SetupPinScreen> {
  _Step _step = _Step.enter;
  String _first = '';
  String _pin = '';
  bool _error = false;
  bool _biometricAvailable = false;
  bool _saving = false;

  Future<void> _onCompleted(String pin) async {
    if (_step == _Step.enter) {
      setState(() {
        _first = pin;
        _pin = '';
        _error = false;
        _step = _Step.confirm;
      });
      return;
    }
    // confirm step
    if (pin != _first) {
      setState(() {
        _error = true;
        _pin = '';
      });
      return;
    }
    setState(() => _saving = true);
    final lock = AppLockScope.read(context);
    await lock.setPin(pin);
    final canBio = await lock.canUseBiometrics();
    if (!mounted) return;
    if (canBio) {
      setState(() {
        _biometricAvailable = true;
        _saving = false;
        _step = _Step.biometric;
      });
    } else {
      _enterApp();
    }
  }

  Future<void> _enableBiometric() async {
    final lock = AppLockScope.read(context);
    final ok =
        await lock.authenticateBiometric(context.strings.biometricReason);
    if (ok) await lock.setBiometricEnabled(true);
    _enterApp();
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    if (_step == _Step.biometric && _biometricAvailable) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 88, color: AppColors.brand500),
                const SizedBox(height: AppSpacing.xl),
                Text(s.enableBiometric,
                    textAlign: TextAlign.center,
                    style: AppType.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(s.useBiometric,
                    textAlign: TextAlign.center,
                    style: AppType.bodyLarge
                        .copyWith(color: AppColors.neutral600)),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton.icon(
                  onPressed: _enableBiometric,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: Text(s.enableBiometric),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(onPressed: _enterApp, child: Text(s.skipForNow)),
              ],
            ),
          ),
        ),
      );
    }

    final title = _step == _Step.enter ? s.setupPinTitle : s.confirmPinTitle;
    final subtitle =
        _step == _Step.enter ? s.setupPinSubtitle : s.confirmPinSubtitle;

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
                      const SizedBox(height: AppSpacing.xl),
                      const Icon(Icons.lock_outline_rounded,
                          size: 56, color: AppColors.brand500),
                      const SizedBox(height: AppSpacing.lg),
                      Text(title, style: AppType.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(subtitle,
                          textAlign: TextAlign.center,
                          style: AppType.bodyLarge
                              .copyWith(color: AppColors.neutral600)),
                      if (_error) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(s.pinMismatch,
                            style: AppType.bodyMedium
                                .copyWith(color: AppColors.danger)),
                      ],
                      const Spacer(),
                      if (_saving)
                        const CircularProgressIndicator()
                      else
                        PinPad(
                          value: _pin,
                          error: _error,
                          onChanged: (v) => setState(() {
                            _pin = v;
                            _error = false;
                          }),
                          onCompleted: _onCompleted,
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
