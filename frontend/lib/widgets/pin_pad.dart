import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// A 6-dot PIN indicator + on-screen numeric keypad. Stateless: the parent
/// owns the entered value and reacts via [onChanged]/[onCompleted].
class PinPad extends StatelessWidget {
  final String value;
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  /// Optional extra key at the bottom-left (e.g. biometric). null hides it.
  final Widget? leadingKey;
  final VoidCallback? onLeadingKey;

  /// Error shake / red dots when true.
  final bool error;

  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.onCompleted,
    this.length = 6,
    this.leadingKey,
    this.onLeadingKey,
    this.error = false,
  });

  void _tap(String digit) {
    if (value.length >= length) return;
    final next = value + digit;
    onChanged(next);
    if (next.length == length) onCompleted?.call(next);
  }

  void _backspace() {
    if (value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value.length
                      ? (error ? AppColors.danger : AppColors.brand500)
                      : Colors.transparent,
                  border: Border.all(
                    color: error ? AppColors.danger : AppColors.neutral300,
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        // keypad
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) _DigitKey(d, () => _tap(d))],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 64,
                child: leadingKey != null
                    ? IconButton(
                        onPressed: onLeadingKey,
                        iconSize: 30,
                        icon: leadingKey!,
                      )
                    : null,
              ),
              _DigitKey('0', () => _tap('0')),
              SizedBox(
                width: 84,
                height: 64,
                child: IconButton(
                  onPressed: _backspace,
                  iconSize: 28,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _DigitKey(this.digit, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 64,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        ),
        child: Text(
          digit,
          style: AppType.headlineMedium.copyWith(color: AppColors.neutral800),
        ),
      ),
    );
  }
}
