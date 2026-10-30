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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width available for the 3-column grid. Fall back to a sane default
        // when unbounded (e.g. inside a scroll view) using the screen width.
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Column gap between keys, scaled but clamped.
        final gap = (maxW * 0.04).clamp(8.0, 20.0);

        // 3 keys + 2 gaps must fit the width. Clamp key width to a comfy range.
        final keyW = ((maxW - gap * 2) / 3).clamp(64.0, 104.0);
        // Keep keys slightly shorter than wide, with a floor for touch targets.
        final keyH = (keyW * 0.74).clamp(52.0, 76.0);

        // Dots & spacing scale with key size.
        final dotSize = (keyW * 0.2).clamp(14.0, 20.0);
        final dotGap = (keyW * 0.1).clamp(6.0, 12.0);

        // Vertical spacing between rows scales a little with key height.
        final rowGap = (keyH * 0.12).clamp(6.0, 14.0);

        final fontSize = (keyW * 0.34).clamp(22.0, 32.0);

        Widget digitKey(String d) => _DigitKey(
              digit: d,
              onTap: () => _tap(d),
              width: keyW,
              height: keyH,
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
                  Container(
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
                        width: 1.5,
                      ),
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
                    width: keyW,
                    height: keyH,
                    child: leadingKey != null
                        ? IconButton(
                            onPressed: onLeadingKey,
                            iconSize: fontSize,
                            icon: leadingKey!,
                          )
                        : null,
                  ),
                  SizedBox(width: gap),
                  digitKey('0'),
                  SizedBox(width: gap),
                  SizedBox(
                    width: keyW,
                    height: keyH,
                    child: IconButton(
                      onPressed: _backspace,
                      iconSize: fontSize * 0.9,
                      icon: const Icon(Icons.backspace_outlined),
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
  final double width;
  final double height;
  final double fontSize;

  const _DigitKey({
    required this.digit,
    required this.onTap,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        ),
        child: Text(
          digit,
          style: AppType.headlineMedium.copyWith(
            fontSize: fontSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
