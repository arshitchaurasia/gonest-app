import 'dart:convert';
import 'package:http/http.dart' as http;

class GokwikServices {
  static const String _customersBaseUrl =
      "https://sandbox-uni-customer.dev.gokwik.io/v3/uni-customers";
  static const String _defaultRequestId =
      "1ba36e08-8527-4d9d-b064-654530f6e45c";
  static const String _defaultSource = "payments";

  static Future<Map<String, dynamic>> getCustomerDetails(
    String customerPhoneNumber
  ) async {
    final url = Uri.parse(
      '$_customersBaseUrl/customers/phone/$customerPhoneNumber',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'gk-request-id': _defaultRequestId,
      'gk-source': _defaultSource,
    };

    try {
      final resp = await http.get(url, headers: headers);

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return Map<String, dynamic>.from(body);
      } else {
        throw Exception(
          'getCustomerDetails failed (${resp.statusCode}): ${resp.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createCustomer(
    String phoneNumber
  ) async {
    final url = Uri.parse('$_customersBaseUrl/customers');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'gk-request-id': _defaultRequestId,
      'gk-source': _defaultSource,
    };

    final payload = {
      'phone': phoneNumber,
    };

    try {
      final resp = await http.post(url, headers: headers, body: jsonEncode(payload));

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return Map<String, dynamic>.from(body);
      } else {
        throw Exception(
          'createCustomer failed (${resp.statusCode}): ${resp.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
