import 'package:flutter_test/flutter_test.dart';
import 'package:checkon/validators/item_form_validators.dart';

void main() {
  test('item name accepts Thai and English letters, digits, and spaces', () {
    expect(
      ItemFormValidators.requiredName(
        'น้ำยาซักผ้า 2',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      isNull,
    );
    expect(
      ItemFormValidators.requiredName(
        'Soap!',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      'invalid',
    );
  });

  test('unit accepts letters only and may be left blank', () {
    expect(ItemFormValidators.optionalLetters('มิลลิลิตร', 'invalid'), isNull);
    expect(ItemFormValidators.optionalLetters('500 ml', 'invalid'), 'invalid');
    expect(ItemFormValidators.optionalLetters('', 'invalid'), isNull);
  });

  test('size and price enforce decimal formats', () {
    expect(ItemFormValidators.optionalDecimal('1.5', 'invalid'), isNull);
    expect(ItemFormValidators.optionalDecimal('1a', 'invalid'), 'invalid');
    expect(
      ItemFormValidators.requiredPrice(
        '12.50',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      isNull,
    );
    expect(
      ItemFormValidators.requiredPrice(
        '12.345',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      'invalid',
    );
  });

  test('quantity must be a positive whole number', () {
    expect(
      ItemFormValidators.positiveInteger(
        '2',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      isNull,
    );
    expect(
      ItemFormValidators.positiveInteger(
        '0',
        requiredMessage: 'required',
        invalidMessage: 'invalid',
      ),
      'invalid',
    );
  });
}