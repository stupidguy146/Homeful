/// Pure password-strength logic (no Flutter deps) so it can be unit-tested
/// and shared between the UI meter and form validation.
library;


/// A single password requirement with a predicate over the candidate password.
class PasswordRule {
  final String id;
  final bool Function(String) test;
  const PasswordRule(this.id, this.test);
}

/// Strength buckets, ordered weakest → strongest.
enum PasswordStrength { weak, fair, good, strong }

class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  /// The rules shown in the UI checklist. `id` maps to an i18n label.
  static final List<PasswordRule> rules = [
    PasswordRule('minLength', (p) => p.length >= minLength),
    PasswordRule('uppercase', (p) => RegExp(r'[A-Z]').hasMatch(p)),
    PasswordRule('lowercase', (p) => RegExp(r'[a-z]').hasMatch(p)),
    PasswordRule('digit', (p) => RegExp(r'[0-9]').hasMatch(p)),
    PasswordRule(
      'special',
      (p) => RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-\[\]\\/;'`~+=]''').hasMatch(p),
    ),
  ];

  /// IDs of rules the password currently satisfies.
  static Set<String> satisfiedRules(String password) {
    return rules.where((r) => r.test(password)).map((r) => r.id).toSet();
  }

  /// Minimum bar to allow account creation: length + at least 3 of the
  /// remaining character-class rules.
  static bool isAcceptable(String password) {
    if (password.length < minLength) return false;
    final classes = rules
        .where((r) => r.id != 'minLength' && r.test(password))
        .length;
    return classes >= 3;
  }

  /// Score 0..4 then mapped to a [PasswordStrength] bucket.
  static PasswordStrength strength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    var score = 0;
    if (password.length >= minLength) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-\[\]\\/;'`~+=]''')
        .hasMatch(password)) {
      score++;
    }
    // collapse 0..5 into 4 buckets
    if (score <= 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.fair;
    if (score == 3) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}
