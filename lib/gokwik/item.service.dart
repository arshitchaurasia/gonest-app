import 'dart:convert';
import 'package:http/http.dart' as http;

class GokwikItemServices {
  static const String _baseUrl = 'https://prod-item-v4.gokwik.io/v3';
  static const String _defaultPlatform = 'shopify';
  static const String _defaultRequestId = 'test-123';

  static Future<Map<String, dynamic>> getMerchantCollections(
    String merchantId,
    String merchantName,
  ) async {
    print(merchantId);
    // merchantId = "12wyqc2guqmkrw6406j";

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'gk-merchant-id': merchantId,
      'gk-is-authenticated': "true",
      'gk-platform': _defaultPlatform,
      'gk-request-id': _defaultRequestId,
    };

    final url = Uri.parse('$_baseUrl/collection/all/$merchantId');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) {
        throw Exception(
          'getMerchantCollections failed (${response.statusCode}): ${response.body}',
        );
      }

      final collectionsJson = jsonDecode(response.body) as Map<String, dynamic>;
      final collectionsData = (collectionsJson['data'] as List<dynamic>? ?? []);

      // Top 3 collections
      final topCollections = collectionsData
          .take(3)
          .map((e) {
            final item = e as Map<String, dynamic>;
            return {
              'collection_id': item['collection_id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
            };
          })
          .where((c) => (c['collection_id'] ?? '').isNotEmpty)
          .toList();

      if (topCollections.isEmpty) {
        return {
          'merchant_id': merchantId,
          'merchant_name': '',
          'collections': [],
        };
      }

      // 2) Get products for top 3 collections
      final collectionIds = topCollections
          .map((e) => e['collection_id'])
          .toList();

      final productsUrl = Uri.parse('$_baseUrl/collection/products');
      final productsResp = await http.post(
        productsUrl,
        headers: headers,
        body: jsonEncode({
          "merchant_id": merchantId,
          "collection_ids": collectionIds,
        }),
      );

      if (productsResp.statusCode != 200) {
        throw Exception(
          'Failed to fetch collection products: ${productsResp.statusCode} ${productsResp.body}',
        );
      }

      final productsJson =
          jsonDecode(productsResp.body) as Map<String, dynamic>;
      final collectionsMap =
          (productsJson['collections'] as Map<String, dynamic>? ?? {});

      // 3) Top 6 products from every collection
      final allProductIds = <String>{};
      final collectionProducts = <Map<String, dynamic>>[];

      for (final collection in topCollections) {
        final ids =
            (collectionsMap[collection['collection_id']] as List<dynamic>? ??
                    [])
                .map((e) => e.toString())
                .take(6)
                .toList();

        allProductIds.addAll(ids);

        collectionProducts.add({
          'collection_id': collection['collection_id'],
          'name': collection['name'],
          'productIds': ids,
        });
      }

      // 4) Get all product details
      final productDetails = await getProductDetails(
        merchantId: merchantId,
        productIds: allProductIds.toList(),
      );

      // Map details by product_id for easy lookup
      final productById = <String, Map<String, dynamic>>{
        for (final p in productDetails) p['product_id'] as String: p,
      };

      // Attach product details to each collection
      final finalCollections = collectionProducts.map((c) {
        final products = (c['productIds'] as List<String>)
            .map((id) => productById[id])
            .whereType<Map<String, dynamic>>()
            .toList();

        return {
          'collection_id': c['collection_id'],
          'name': c['name'],
          'products': products,
        };
      }).toList();

      return {
        "merchant_id": merchantId,
        "merchant_name": merchantName,
        "collections": finalCollections,
      };
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCollectionProducts(
    String merchantId,
    String collectionId,
    String collectionName,
  ) async {
    print(merchantId);
   // merchantId = "12wyqc2guqmkrw6406j";

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'gk-merchant-id': merchantId,
      'gk-is-authenticated': 'true',
      'gk-platform': _defaultPlatform,
      'gk-request-id': _defaultRequestId,
    };

    final url = Uri.parse('$_baseUrl/collection/products');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "merchant_id": merchantId,
          "collection_ids": [collectionId],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch collection products: ${response.statusCode} ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final collectionsMap =
          (json['collections'] as Map<String, dynamic>? ?? {});
      final productIds = (collectionsMap[collectionId] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      if (productIds.isEmpty) {
        return {
          "merchant_id": merchantId,
          "collection_id": collectionId,
          "products": [],
        };
      }

      final products = await getProductDetails(
        merchantId: merchantId,
        productIds: productIds,
      );

      return {
        "merchant_id": merchantId,
        "collection_id": collectionId,
        "name": collectionName,
        "products": products,
      };
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getProductDetails({
    required String merchantId,
    required List<String> productIds,
  }) async {
    print(merchantId);
   // merchantId = "12wyqc2guqmkrw6406j";

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'gk-merchant-id': merchantId,
      'gk-is-authenticated': "true",
      'gk-platform': _defaultPlatform,
      'gk-request-id': _defaultRequestId,
    };

    final url = Uri.parse('$_baseUrl/product/get-product-details');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "product_query": productIds.map((id) => {"product_id": id}).toList(),
          "is_deleted": false,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch product details: ${response.statusCode} ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as List<dynamic>? ?? []);

      return data
          .map((p) => p as Map<String, dynamic>)
          .where(
            (p) =>
                p['product_id'] != null &&
                p['product_id'].toString().isNotEmpty,
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
