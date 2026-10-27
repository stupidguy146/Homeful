import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:room_shopping_app/models/household_item.dart';
import 'package:room_shopping_app/services/product_lookup_service.dart';

void main() {
  test('maps barcode product details for the add form', () async {
    final service = ProductLookupService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v2/product/123456789.json');
        if (request.url.host == 'world.openproductsfacts.org') {
          return http.Response(jsonEncode({'status': 0}), 200);
        }
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Dish Soap',
              'product_quantity': '500 ml',
              'product_quantity_unit': 'ml',
              'categories_tags': ['en:dishwashing-products'],
            },
          }),
          200,
        );
      }),
    );

    final product = await service.lookup('123456789');

    expect(product?.name, 'Dish Soap');
    expect(product?.size, '500');
    expect(product?.unit, 'ml');
    expect(product?.category, ItemCategory.kitchen);
  });

  test('returns null when the barcode is not in the product database', () async {
    final service = ProductLookupService(
      client: MockClient((_) async => http.Response(jsonEncode({'status': 0}), 200)),
    );

    expect(await service.lookup('000000000'), isNull);
  });
}