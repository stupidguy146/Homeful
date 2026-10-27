import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_lock_scope.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pin_pad.dart';
import '../i18n/locale_scope.dart';

/// Change (or set) the local app-unlock PIN from the menu. Flow:
///   current → verify the existing PIN (skipped if none is set yet)
///   enter   → type the new PIN
///   confirm → retype to confirm, then save
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _Step { current, enter, confirm }

class _ChangePinScreenState extends State<ChangePinScreen> {
  _Step _step = _Step.enter;
  bool _hasPin = false;
  bool _checked = false;
  String _newFirst = '';
  String _pin = '';
  bool _error = false;
  String? _errorText;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _init();
    }
  }

  Future<void> _init() async {
    final has = await AppLockScope.read(context).hasPin();
    if (!mounted) return;
    setState(() {
      _hasPin = has;
      _step = has ? _Step.current : _Step.enter;
    });
  }

  Future<void> _onCompleted(String pin) async {
    final s = context.strings;
    final lock = AppLockScope.read(context);

    switch (_step) {
      case _Step.current:
        final ok = await lock.verifyPin(pin);
        if (!mounted) return;
        if (ok) {
          setState(() {
            _step = _Step.enter;
            _pin = '';
            _error = false;
            _errorText = null;
          });
        } else {
          setState(() {
            _error = true;
            _errorText = s.wrongPin;
            _pin = '';
          });
        }
        break;
      case _Step.enter:
        setState(() {
          _newFirst = pin;
          _step = _Step.confirm;
          _pin = '';
          _error = false;
          _errorText = null;
        });
        break;
      case _Step.confirm:
        if (pin != _newFirst) {
          setState(() {
            _error = true;
            _errorText = s.pinMismatch;
            _pin = '';
          });
          return;
        }
        setState(() => _saving = true);
        await lock.setPin(pin);
        if (!mounted) return;
        AppSnackBar.success(context, s.pinChanged);
        Navigator.pop(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final (title, subtitle) = switch (_step) {
      _Step.current => (s.enterCurrentPin, s.enterCurrentPinSubtitle),
      _Step.enter => (s.setupPinTitle, s.setupPinSubtitle),
      _Step.confirm => (s.confirmPinTitle, s.confirmPinSubtitle),
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              subtitle: s.security,
              title: _hasPin ? s.changePin : s.setupPinTitle,
              leading: _HeaderBackButton(onTap: () => Navigator.pop(context)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  const Icon(Icons.pin_rounded,
                      size: 56, color: AppColors.brand500),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title, style: AppType.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: AppType.bodyLarge
                          .copyWith(color: AppColors.neutral600)),
                  if (_error && _errorText != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_errorText!,
                        style: AppType.bodyMedium
                            .copyWith(color: AppColors.danger)),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HeaderBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
