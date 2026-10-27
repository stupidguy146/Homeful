import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/household_item.dart';

class ProductLookup {
  final String name;
  final String? size;
  final String? unit;
  final ItemCategory? category;

  const ProductLookup({
    required this.name,
    this.size,
    this.unit,
    this.category,
  });
}

class ProductLookupService {
  final http.Client _client;

  ProductLookupService({http.Client? client}) : _client = client ?? http.Client();

  void close() => _client.close();

  Future<ProductLookup?> lookup(String barcode) async {
    Object? lastError;
    for (final host in [
      'world.openproductsfacts.org',
      'world.openfoodfacts.org',
    ]) {
      try {
        final product = await _lookupAt(host, barcode);
        if (product != null) return product;
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  Future<ProductLookup?> _lookupAt(String host, String barcode) async {
    final uri = Uri.https(
      host,
      '/api/v2/product/$barcode.json',
      {
        'fields':
            'product_name,product_name_en,product_quantity,product_quantity_unit,categories_tags',
      },
    );
    final response = await _client.get(
      uri,
      headers: {'User-Agent': 'homeful/1.0 (Room Shopping List)'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Product lookup failed (${response.statusCode})',
        uri,
      );
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['status'] != 1) return null;
    final product = result['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final name = _firstNonEmpty([
      product['product_name'],
      product['product_name_en'],
    ]);
    if (name == null) return null;

    final quantity = product['product_quantity']?.toString().trim() ?? '';
    final quantityMatch = RegExp(r'^([0-9]+(?:[.,][0-9]+)?)\s*(.*)$')
        .firstMatch(quantity);
    final quantityUnit = product['product_quantity_unit']?.toString().trim();
    final unitFromQuantity = quantityMatch?.group(2)?.trim();

    return ProductLookup(
      name: name,
      size: quantityMatch?.group(1)?.replaceAll(',', '.'),
      unit: (unitFromQuantity?.isNotEmpty ?? false)
          ? unitFromQuantity
          : (quantityUnit?.isNotEmpty ?? false)
              ? quantityUnit
              : null,
      category: _categoryFromTags(product['categories_tags']),
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  ItemCategory? _categoryFromTags(dynamic value) {
    if (value is! List) return null;
    final tags = value.whereType<String>().map((tag) => tag.toLowerCase());
    for (final tag in tags) {
      if (tag.contains('dishwashing') || tag.contains('kitchen-cleaner')) {
        return ItemCategory.kitchen;
      }
      if (tag.contains('laundry') ||
          tag.contains('detergent') ||
          tag.contains('washing')) {
        return ItemCategory.laundry;
      }
      if (tag.contains('bathroom') || tag.contains('toilet')) {
        return ItemCategory.bathroom;
      }
      if (tag.contains('personal-care') ||
          tag.contains('shampoo') ||
          tag.contains('cosmetic') ||
          tag.contains('oral-hygiene')) {
        return ItemCategory.personal;
      }
      if (tag.contains('food') || tag.contains('beverage')) {
        return ItemCategory.food;
      }
    }
    return null;
  }
}