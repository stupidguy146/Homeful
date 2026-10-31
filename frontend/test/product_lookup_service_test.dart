import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:checkon/models/household_item.dart';
import 'package:checkon/services/product_lookup_service.dart';

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
              'brands': 'Sunlight',
              'product_quantity': '500 ml',
              'product_quantity_unit': 'ml',
              'categories_tags': ['en:dishwashing-products'],
              'stores': 'Tesco Lotus,7-Eleven',
              'image_front_url': 'https://img.example/dish.jpg',
            },
          }),
          200,
        );
      }),
    );

    final product = await service.lookup('123456789');

    expect(product?.name, 'Dish Soap');
    expect(product?.brand, 'Sunlight');
    expect(product?.displayName, 'Sunlight Dish Soap');
    expect(product?.size, '500');
    expect(product?.unit, 'ml');
    expect(product?.category, ItemCategory.kitchen);
    expect(product?.store, 'Tesco Lotus'); // first store only
    expect(product?.imageUrl, 'https://img.example/dish.jpg');
  });

  test('returns null when the barcode is not in the product database', () async {
    final service = ProductLookupService(
      client: MockClient((_) async => http.Response(jsonEncode({'status': 0}), 200)),
    );

    expect(await service.lookup('000000000'), isNull);
  });

  test('falls back to the other host when the first returns 404', () async {
    // Mirrors the real API: openproductsfacts returns HTTP 404 with status:0
    // for a food item, which must not abort the lookup — openfoodfacts has it.
    final service = ProductLookupService(
      client: MockClient((request) async {
        if (request.url.host == 'world.openproductsfacts.org') {
          return http.Response(
            jsonEncode({
              'code': '8851351933330',
              'status': 0,
              'status_verbose':
                  'product found with a different product type: food',
            }),
            404,
          );
        }
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Blueberry Cupcake',
              'categories_tags': ['en:snacks', 'en:sweet-snacks'],
            },
          }),
          200,
        );
      }),
    );

    final product = await service.lookup('8851351933330');
    expect(product?.name, 'Blueberry Cupcake');
    expect(product?.category, ItemCategory.food);
  });

  test('fetchImageAsDataUrl returns a base64 data URL for an image response',
      () async {
    final service = ProductLookupService(
      client: MockClient((request) async {
        return http.Response.bytes(
          [1, 2, 3, 4],
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }),
    );
    final dataUrl =
        await service.fetchImageAsDataUrl('https://img.example/x.jpg');
    expect(dataUrl, startsWith('data:image/jpeg;base64,'));
  });

  test('fetchImageAsDataUrl returns null for a non-image response', () async {
    final service = ProductLookupService(
      client: MockClient((_) async => http.Response('not found', 404)),
    );
    final dataUrl =
        await service.fetchImageAsDataUrl('https://img.example/missing.jpg');
    expect(dataUrl, isNull);
  });
}