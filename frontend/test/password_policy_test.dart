import 'package:flutter_test/flutter_test.dart';
import 'package:room_shopping_app/validators/password_policy.dart';

void main() {
  group('PasswordPolicy.satisfiedRules', () {
    test('empty password satisfies nothing', () {
      expect(PasswordPolicy.satisfiedRules(''), isEmpty);
    });

    test('a strong password satisfies all rules', () {
      final rules = PasswordPolicy.satisfiedRules('Abcdef1!');
      expect(rules, containsAll(['minLength', 'uppercase', 'lowercase', 'digit', 'special']));
    });

    test('lowercase-only short password satisfies only lowercase', () {
      expect(PasswordPolicy.satisfiedRules('abc'), {'lowercase'});
    });
  });

  group('PasswordPolicy.isAcceptable', () {
    test('rejects short passwords', () {
      expect(PasswordPolicy.isAcceptable('Ab1!'), isFalse);
    });

    test('rejects long but single-class passwords', () {
      expect(PasswordPolicy.isAcceptable('aaaaaaaaaaaa'), isFalse);
    });

    test('accepts 8+ chars with 3 character classes', () {
      expect(PasswordPolicy.isAcceptable('Abcdefg1'), isTrue); // upper+lower+digit
    });

    test('accepts a full strong password', () {
      expect(PasswordPolicy.isAcceptable('Str0ng!Pass'), isTrue);
    });
  });

  group('PasswordPolicy.strength', () {
    test('empty is weak', () {
      expect(PasswordPolicy.strength(''), PasswordStrength.weak);
    });

    test('long password with all classes is strong', () {
      expect(
        PasswordPolicy.strength('VeryStr0ng!Pass'),
        PasswordStrength.strong,
      );
    });

    test('monotonic: strength never decreases as complexity grows', () {
      final weak = PasswordPolicy.strength('aaaa');
      final fair = PasswordPolicy.strength('Abcdefgh');
      final strong = PasswordPolicy.strength('Abcdefg1!xyz');
      expect(weak.index, lessThanOrEqualTo(fair.index));
      expect(fair.index, lessThanOrEqualTo(strong.index));
    });
  });
}
