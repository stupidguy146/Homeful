import 'package:checkon/theme/app_tokens.dart';
import 'package:checkon/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PIN keys are slightly larger', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PinPad(value: '', onChanged: _ignorePinChange),
          ),
        ),
      ),
    );

    final key = find.ancestor(
      of: find.text('1'),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(key), const Size(86, 86));
  });

  testWidgets('PIN key is clear until pressed and still reports taps',
      (tester) async {
    final enteredPins = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PinPad(value: '', onChanged: enteredPins.add),
          ),
        ),
      ),
    );

    final key = find.ancestor(
      of: find.text('1'),
      matching: find.byType(AnimatedContainer),
    );
    BoxDecoration decoration() =>
        tester.widget<AnimatedContainer>(key).decoration! as BoxDecoration;

    expect(decoration().color, Colors.transparent);
    expect(decoration().gradient, isNull);
    expect(decoration().boxShadow, isNull);
    expect((decoration().border! as Border).top.color, Colors.transparent);

    final gesture = await tester.press(find.text('1'));
    await tester.pump();

    expect(decoration().color, AppColors.brand50);
    expect((decoration().border! as Border).top.color,
        AppColors.brand500.withValues(alpha: 0.7));

    await gesture.up();
    await tester.pump();

    expect(enteredPins, ['1']);
    expect(decoration().color, Colors.transparent);
    expect((decoration().border! as Border).top.color, Colors.transparent);
  });
}

void _ignorePinChange(String _) {}
