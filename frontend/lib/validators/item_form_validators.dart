class ItemFormValidators {
  static final nameCharacters =
      RegExp(r'[A-Za-z0-9\u0E01-\u0E2E\u0E30-\u0E3A\u0E40-\u0E4E ]');
  static final letterCharacters =
      RegExp(r'[A-Za-z\u0E01-\u0E2E\u0E30-\u0E3A\u0E40-\u0E4E ]');
  static final decimalInput = RegExp(r'^\d*\.?\d*$');
  static final priceInput = RegExp(r'^\d*\.?\d{0,2}$');

  static final _namePattern =
      RegExp(r'^[A-Za-z0-9\u0E01-\u0E2E\u0E30-\u0E3A\u0E40-\u0E4E ]+$');
  static final _lettersPattern =
      RegExp(r'^[A-Za-z\u0E01-\u0E2E\u0E30-\u0E3A\u0E40-\u0E4E ]+$');
  static final _decimalPattern = RegExp(r'^\d+(?:\.\d+)?$');
  static final _pricePattern = RegExp(r'^\d+(?:\.\d{1,2})?$');

  static String? requiredName(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredMessage;
    return _namePattern.hasMatch(text) ? null : invalidMessage;
  }

  static String? optionalLetters(String? value, String invalidMessage) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _lettersPattern.hasMatch(text) ? null : invalidMessage;
  }

  static String? optionalName(String? value, String invalidMessage) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _namePattern.hasMatch(text) ? null : invalidMessage;
  }

  static String? optionalDecimal(String? value, String invalidMessage) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _decimalPattern.hasMatch(text) ? null : invalidMessage;
  }

  static String? positiveInteger(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final text = value?.trim() ?? '';
    final quantity = int.tryParse(text);
    if (quantity == null) return requiredMessage;
    return quantity > 0 ? null : invalidMessage;
  }

  static String? requiredPrice(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredMessage;
    if (!_pricePattern.hasMatch(text)) return invalidMessage;
    return (double.tryParse(text) ?? -1) >= 0 ? null : invalidMessage;
  }
}