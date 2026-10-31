import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/household_item.dart';

class ProductLookup {
  final String name;
  final String? brand;
  final String? size;
  final String? unit;
  final ItemCategory? category;
  final String? store;
  final String? imageUrl;

  const ProductLookup({
    required this.name,
    this.brand,
    this.size,
    this.unit,
    this.category,
    this.store,
    this.imageUrl,
  });

  /// Display name including the brand when available, e.g. "Lepan Blueberry Cupcake".
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      final b = brand!.trim();
      // avoid duplicating the brand if the name already starts with it
      if (!name.toLowerCase().startsWith(b.toLowerCase())) {
        return '$b $name';
      }
    }
    return name;
  }
}

class ProductLookupService {
  final http.Client _client;

  ProductLookupService({http.Client? client}) : _client = client ?? http.Client();

  void close() => _client.close();

  Future<ProductLookup?> lookup(String barcode) async {
    Object? lastError;
    // Try the food database first — most retail barcodes (esp. in TH) are
    // food/beverage. Fall back to the general products DB. A 404 at one host
    // just means "not here", so we quietly try the next.
    for (final host in [
      'world.openfoodfacts.org',
      'world.openproductsfacts.org',
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

  /// Download a product image URL and return it as a base64 data URL suitable
  /// for the item form / backend. Returns null on any failure (image optional).
  Future<String?> fetchImageAsDataUrl(String url) async {
    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final contentType = res.headers['content-type'] ?? 'image/jpeg';
      final mime = contentType.split(';').first.trim();
      if (!mime.startsWith('image/')) return null;
      return 'data:$mime;base64,${base64Encode(res.bodyBytes)}';
    } catch (_) {
      return null;
    }
  }

  Future<ProductLookup?> _lookupAt(String host, String barcode) async {
    final uri = Uri.https(
      host,
      '/api/v2/product/$barcode.json',
      {
        'fields':
            'product_name,product_name_en,brands,product_quantity,product_quantity_unit,categories_tags,stores,image_front_url,image_url,image_front_small_url,image_front_thumb_url',
      },
    );
    final response = await _client.get(
      uri,
      headers: {'User-Agent': 'Checkon/1.0 (Checkon household app)'},
    );
    // 404 = product not found at this host (the API returns a JSON body with
    // status:0). Treat as "no result here" and let the caller try the next
    // host, rather than throwing.
    if (response.statusCode == 404) return null;
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

    final brand = _firstBrand(product['brands']);
    final store = _firstStore(product['stores']);
    final imageUrl = _firstNonEmpty([
      product['image_front_url'],
      product['image_url'],
      product['image_front_small_url'],
      product['image_front_thumb_url'],
    ]);

    return ProductLookup(
      name: name,
      brand: brand,
      size: quantityMatch?.group(1)?.replaceAll(',', '.'),
      unit: (unitFromQuantity?.isNotEmpty ?? false)
          ? unitFromQuantity
          : (quantityUnit?.isNotEmpty ?? false)
              ? quantityUnit
              : null,
      category: _categoryFromTags(product['categories_tags']),
      store: store,
      imageUrl: imageUrl,
    );
  }

  /// `brands` is a comma-separated string; take the first brand.
  String? _firstBrand(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.split(',').first.trim();
  }

  /// `stores` is a comma-separated string; take the first store.
  String? _firstStore(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.split(',').first.trim();
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
      if (tag.contains('food') ||
          tag.contains('beverage') ||
          tag.contains('drink') ||
          tag.contains('snack') ||
          tag.contains('sweet') ||
          tag.contains('cake') ||
          tag.contains('dairy') ||
          tag.contains('bread') ||
          tag.contains('cereal')) {
        return ItemCategory.food;
      }
    }
    return null;
  }
}