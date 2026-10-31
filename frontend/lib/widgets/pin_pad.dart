import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// A 6-dot PIN indicator + on-screen numeric keypad. Stateless: the parent
/// owns the entered value and reacts via [onChanged]/[onCompleted].
///
/// The keypad is responsive: key size, spacing and dot size are derived from
/// the available width (and capped by height) so it fills narrow phone
/// screens without overflowing on very small or very large viewports.
class PinPad extends StatelessWidget {
  final String value;
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final double maxKeySize;

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
    this.maxKeySize = 86,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width available for the 3-column grid. Fall back to a sane default
        // when unbounded (e.g. inside a scroll view) using the screen width.
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final gap = (maxW * 0.07).clamp(12.0, 22.0).toDouble();
        var keySize = ((maxW - gap * 2) / 3).clamp(64.0, 86.0).toDouble();
        if (constraints.maxHeight.isFinite) {
          final heightLimit = (constraints.maxHeight / 5.24).clamp(40.0, 86.0);
          keySize = keySize.clamp(40.0, heightLimit).toDouble();
        }
        keySize = keySize.clamp(40.0, maxKeySize.clamp(40.0, 86.0)).toDouble();
        final dotSize = (keySize * 0.2).clamp(14.0, 18.0).toDouble();
        final dotGap = (keySize * 0.1).clamp(6.0, 10.0).toDouble();
        final rowGap = (keySize * 0.1).clamp(6.0, 9.0).toDouble();
        final fontSize = (keySize * 0.38).clamp(24.0, 32.0).toDouble();

        Widget digitKey(String d) => _DigitKey(
              digit: d,
              onTap: () => _tap(d),
              size: keySize,
              fontSize: fontSize,
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: EdgeInsets.symmetric(horizontal: dotGap),
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < value.length
                          ? (error ? AppColors.danger : AppColors.brand500)
                          : Colors.transparent,
                      border: Border.all(
                        color: error ? AppColors.danger : AppColors.neutral300,
                        width: i < value.length ? 0 : 1.5,
                      ),
                      boxShadow: i < value.length
                          ? [
                              BoxShadow(
                                color: (error
                                        ? AppColors.danger
                                        : AppColors.brand500)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
              ],
            ),
            SizedBox(height: rowGap * 2.4),
            // keypad
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Padding(
                padding: EdgeInsets.symmetric(vertical: rowGap),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      if (i != 0) SizedBox(width: gap),
                      digitKey(row[i]),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: rowGap),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: keySize,
                    height: keySize,
                    child: leadingKey == null
                        ? null
                        : _PinUtilityKey(
                            icon: leadingKey!,
                            onTap: onLeadingKey,
                            size: keySize,
                          ),
                  ),
                  SizedBox(width: gap),
                  digitKey('0'),
                  SizedBox(width: gap),
                  SizedBox(
                    width: keySize,
                    height: keySize,
                    child: _PinUtilityKey(
                      icon: Icon(
                        Icons.backspace_outlined,
                        size: fontSize * 0.78,
                      ),
                      onTap: _backspace,
                      size: keySize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DigitKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  final double size;
  final double fontSize;

  const _DigitKey({
    required this.digit,
    required this.onTap,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PinKeySurface(
      size: size,
      onTap: onTap,
      child: Text(
        digit,
        style: AppType.callout.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _PinUtilityKey extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double size;

  const _PinUtilityKey({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PinKeySurface(
      size: size,
      onTap: onTap,
      child: IconTheme(
        data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
        child: icon,
      ),
    );
  }
}

class _PinKeySurface extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final Widget child;

  const _PinKeySurface({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  State<_PinKeySurface> createState() => _PinKeySurfaceState();
}

class _PinKeySurfaceState extends State<_PinKeySurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: widget.size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? (isDark ? AppColors.darkSurfaceAlt : AppColors.brand50)
                : Colors.transparent,
            border: Border.all(
              color: _pressed
                  ? AppColors.brand500.withValues(alpha: 0.7)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: AppColors.brand900.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Ink(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (pressed) {
                if (_pressed != pressed) setState(() => _pressed = pressed);
              },
              customBorder: const CircleBorder(),
              splashColor: AppColors.brand400.withValues(alpha: 0.2),
              highlightColor: AppColors.brand300.withValues(alpha: 0.12),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
