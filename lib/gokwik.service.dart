import 'dart:convert';
import 'package:http/http.dart' as http;

class GokwikServices {
  // Base configuration (change merchantId/requestId/platform if needed)
  static const String _baseUrl = 'https://sandbox-auth.dev.gokwik.io/v3/auth';
  static const String _defaultMerchantId = 'eey3k3mkrg55tcs';
  static const String _defaultPlatform = 'shopify';
  static const String _defaultRequestId = 'test-123';

  /// Sends OTP to [phone].
  /// Returns decoded JSON response on success.
  /// Throws Exception on non-2xx responses or on network/json errors.
  static Future<Map<String, dynamic>> sendOtp(
    String phone, {
    String merchantId = _defaultMerchantId,
    String event = 'AUTH_OTP',
    String source = 'address_service',
    String gkRequestId = _defaultRequestId,
    String gkPlatform = _defaultPlatform,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    
    final url = Uri.parse('$_baseUrl/send_otp');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'gk-request-id': gkRequestId,
      'gk-platform': gkPlatform,
    };

    final payload = {
      'phone': phone,
      'merchant_id': merchantId,
      'event': event,
      'source': source,
    };

    try {

      final response = await http
          .post(url, headers: headers, body: jsonEncode(payload));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Map<String, dynamic>.from(body);
      } else {
        throw Exception(
            'sendOtp failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verifies [otp] for [phone].
  /// Returns decoded JSON response on success.
  /// Throws Exception on non-2xx responses or on network/json errors.
  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    int otp, {
    String merchantId = _defaultMerchantId,
    String source = 'address_service',
    String gkRequestId = _defaultRequestId,
    String gkPlatform = _defaultPlatform,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final url = Uri.parse('$_baseUrl/verify_otp');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'gk-request-id': gkRequestId,
      'gk-platform': gkPlatform,
    };

    final payload = {
      'phone': phone,
      'merchant_id': merchantId,
      'otp': otp,
      'source': source,
    };

    try {

      final response = await http
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Map<String, dynamic>.from(body);
      } else {
        throw Exception(
            'verifyOtp failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
    }

    // 🔥 NEW CHECKOUT API
  static Future<String?> createCheckoutLink(
    int variantId, String website) async {

  final url = Uri.parse(
    "https://prod-core-api-v4.gokwik.io/v1/internal/checkout-link"
  );

  final headers = {
    "Content-Type": "application/json",
    "auth-key": "EB452B6BA73B11F2A36557E2391A4",
  };

  final payload = {
    "title": "checkout from app",
    "products": [
      {
        "variant_id": variantId,
        "quantity": 1
      }
    ],
    "website": website, // 👈 dynamic now
    "source": "api"
  };

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    print("Status Code: ${response.statusCode}");
    print("Raw Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["data"]?["checkout_link_data"]?["checkout_url"];
    } else {
      print("Error: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Checkout API Error: $e");
    return null;
  }
}
    // WebHook
  static Future<void> sendToWebhook(Map data) async {
  final url = Uri.parse(
   "https://script.google.com/macros/s/AKfycbyItmXa_kpYtDwRqSFj7v4akExxlUcczKh1t6qzhPFkO8JBDqEVhp5SBsq_bZ7F0bat/exec"
  );

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print("Response: ${response.body}");
  } catch (e) {
    print("Error: $e");
  }
}

}