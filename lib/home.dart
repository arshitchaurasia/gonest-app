import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:gonest/checkout_webview.dart';
import 'package:digia_ui/digia_ui.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gonest/gokwik.service.dart';
import 'package:gonest/gokwik/item.service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with DigiaMessageHandlerMixin {
  @override
  void initState() {
    super.initState();

    // Handler to receive a sendOTP event from the Digia web layer.

    addMessageHandler('sendOTP', (event) async {
      try {
        await GokwikServices.sendOtp(
          (event.payload as Map<String, dynamic>)['phone'],
        );

        print("Data : ${DUIAppState().getValue("user")}");
        FirebaseAnalytics.instance.logEvent(
          name: "otpSent",
          parameters: {"phone": DUIAppState().getValue("user")['phone']},
        );
      } catch (e) {
        print("Error  : $e");
      }
    });

    // Handler to buy now

    addMessageHandler('buyNow', (event) async {
      try {
        final payload = event.payload as Map<String, dynamic>;

        final variantId = int.tryParse(payload['variantId'].toString());
        final productUrl = payload['productUrl'];

        if (variantId == null || productUrl == null) {
          print("Variant ID or Product URL missing");
          return;
        }
        if (variantId == null || productUrl == null) {
          print("Variant ID or Product URL missing");
          return;
        }

        final uri = Uri.parse(productUrl);
        final website = uri.host; // 👈 THIS IS KEY

        final checkoutUrl = await GokwikServices.createCheckoutLink(
          variantId,
          website,
        );

        print("checkoutUrl: $checkoutUrl");
        print("checkoutUrl: $checkoutUrl");

        if (checkoutUrl == null) {
          print("checkoutUrl not received");
          return;
        }
        if (checkoutUrl == null) {
          print("checkoutUrl not received");
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CheckoutWebView(url: checkoutUrl)),
        );
      } catch (e) {
        print("Buy Now Error: $e");
      }
    });

    addMessageHandler('loadHomeSections', (event) async {
      try {
        final payload = event.payload as Map<String, dynamic>;
        final merchants = payload['merchants'] as List<dynamic>? ?? [];
        final top4Merchants = merchants.take(4).toList();

        // Section 1: Top Brands (all merchants as brand entries)
        final brands = merchants.map((m) {
          final merchant = m as Map<String, dynamic>;
          return {
            'merchant_id': merchant['merchant_id'] ?? '',
            'name': merchant['name'] ?? '',
            'logo': merchant['logo'] ?? '',
          };
        }).toList();

        final homeSections = <Map<String, dynamic>>[
          // {'id': 1, 'name': 'Top Brands', 'brands': brands},
        ];

        // Sections 2+: One section per top merchant with their products
        int sectionId = 2;
        for (final merchant in top4Merchants) {
          final merchantMap = merchant as Map<String, dynamic>;
          final merchantId = merchantMap['merchant_id'] as String?;
          final merchantName = merchantMap['name'] as String?;

          if (merchantId == null || merchantName == null) {
            print("Merchant ID or Name is missing, skipping");
            continue;
          }

          try {
            final products = await GokwikItemServices.getMerchantProducts(
              merchantId: merchantId,
              page: 1,
              limit: 10,
            );

            homeSections.add({
              'id': sectionId,
              'name': merchantName,
              'merchant_id': merchantId,
              'products': products,
            });

            sectionId++;
          } catch (e) {
            print("Failed to fetch products for $merchantName: $e");
          }
        }

        DUIAppState().update<List<dynamic>>("homeTabSections", homeSections);

        // DUIPageController().rebuild();
      } catch (e) {
        print("loadHomeSections Error: $e");
      }
    });

    addMessageHandler('verifyOTP', (event) async {
      final phone = (event.payload as Map<String, dynamic>)["phone"];
      final otp = (event.payload as Map<String, dynamic>)["otp"];

      if (phone == null || otp == null) {
        print("Phone and OTP is required");
        return;
      }

      print("Phone : $phone");
      print("OTP : $otp");

      try {
        final resp = await GokwikServices.verifyOtp(phone, int.parse(otp));

        if (resp["data"]["otp_verified"]) {
          // get user details

          await FirebaseAnalytics.instance.logEvent(
            name: "otpVerified",
            parameters: {"phone": DUIAppState().getValue("user")['phone']},
          );

          Navigator.of(
            context,
          ).push(DUIFactory().createPageRoute("main_screen-LvNIGi", null));
        } else {
          Fluttertoast.showToast(
            msg: resp["data"]["error_message"] ?? "Something went wrong",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
      } catch (e) {
        print("Error  : $e");
      }
    });

    addMessageHandler('getMerchantCollections', (event) async {
      DUIAppState().update<Map<String, dynamic>>("api", {
        "isLoading": true,
        "message": "Loading",
        "data": null,
      });

      final merchantId = (event.payload as Map<String, dynamic>)["merchant_id"];
      final merchantName =
          (event.payload as Map<String, dynamic>)["merchant_name"];

      print("Merchant Name : $merchantName");
      print("Merchant ID : $merchantId");

      Navigator.of(context).push(
        DUIFactory().createPageRoute("brand_page-5wJ4NG", {
          "brand": null,
          "brandName": merchantName,
        }),
      );

      if (merchantId == null) {
        print("Merchant ID is required");
        return;
      }

      try {
        final resp = await GokwikItemServices.getMerchantCollections(
          merchantId,
          merchantName,
        );

        if (resp["collections"].isEmpty) {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "No collections found",
            "data": resp,
          });
        } else {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "Done",
            "data": resp,
          });
        }
      } catch (e) {
        DUIAppState().update<Map<String, dynamic>>("api", {
          "isLoading": false,
          "message": "Something went wrong",
          "data": null,
        });
        print("Error  : $e");
      }
    });

    addMessageHandler('getCollectionProducts', (event) async {
      DUIAppState().update<Map<String, dynamic>>("api", {
        "isLoading": true,
        "message": "Loading",
        "data": null,
      });

      final merchantId = (event.payload as Map<String, dynamic>)["merchant_id"];
      final collectionId =
          (event.payload as Map<String, dynamic>)["collection_id"];
      final collectionName =
          (event.payload as Map<String, dynamic>)["collection_name"];

      print("Merchant ID : $merchantId");
      print("Collection ID : $collectionId");

      Navigator.of(context).push(
        DUIFactory().createPageRoute("collection_results-5XrEMK", {
          "collectionName": collectionName,
        }),
      );

      if (collectionId == null || merchantId == null) {
        print("Collection ID and Merchant ID is required");
        return;
      }

      try {
        final resp = await GokwikItemServices.getCollectionProducts(
          merchantId,
          collectionId,
          collectionName,
        );

        if (resp["products"].isEmpty) {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "No products found",
            "data": resp,
          });
        } else {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "Done",
            "data": resp,
          });
        }
      } catch (e) {
        DUIAppState().update<Map<String, dynamic>>("api", {
          "isLoading": false,
          "message": "Something went wrong",
          "data": null,
        });
        print("Error  : $e");
      }
    });

    addMessageHandler('kycSubmit', (event) async {
      final data = event.payload as Map<String, dynamic>;
      print("KYC Data: $data");
      await GokwikServices.sendToWebhook(data);
    });

    addMessageHandler("getProductDetails", (event) async {
      DUIAppState().update<Map<String, dynamic>>("api", {
        "isLoading": true,
        "message": "Loading",
        "data": null,
      });

      Navigator.of(
        context,
      ).push(DUIFactory().createPageRoute("pdp-QS3XcE", null));

      final merchantId = (event.payload as Map<String, dynamic>)["merchant_id"];
      final productId = (event.payload as Map<String, dynamic>)["product_id"];

      if (productId == null || merchantId == null) {
        print("Product ID and Merchant ID is required");
        return;
      }

      try {
        final resp = await GokwikItemServices.getProductDetails(
          merchantId: merchantId,
          productIds: [productId],
        );

        final product = (resp as List<dynamic>?)?.isNotEmpty == true
            ? resp[0]
            : null;

        if (product == null) {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "Product not found",
            "data": product,
          });
          print("No product found");
        } else {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "Done",
            "data": product,
          });
        }
      } catch (e) {
        DUIAppState().update<Map<String, dynamic>>("api", {
          "isLoading": false,
          "message": "Something went wrong",
          "data": null,
        });
        print("Error  : $e");
      }
    });

    addMessageHandler("getMerchantProducts", (event) async {
      DUIAppState().update<Map<String, dynamic>>("api", {
        "isLoading": true,
        "message": "Loading",
        "data": null,
      });

      final merchantId = (event.payload as Map<String, dynamic>)["merchant_id"];
      final merchantName =
          (event.payload as Map<String, dynamic>)["merchant_name"];
      final page =
          int.tryParse(
            (event.payload as Map<String, dynamic>)["page"]?.toString() ?? "",
          ) ??
          1;
      final limit =
          int.tryParse(
            (event.payload as Map<String, dynamic>)["limit"]?.toString() ?? "",
          ) ??
          10;

      if (merchantId == null) {
        print("Merchant ID is required");
        return;
      }

      Navigator.of(context).push(
        DUIFactory().createPageRoute("brand_products-us6xXK", {
          "heading": merchantName,
        }),
      );

      try {
        final products = await GokwikItemServices.getMerchantProducts(
          merchantId: merchantId,
          page: page,
          limit: limit,
        );

        final resp = {"products": products};

        if (products.isEmpty) {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "No products found",
            "data": resp,
          });
        } else {
          DUIAppState().update<Map<String, dynamic>>("api", {
            "isLoading": false,
            "message": "Done",
            "data": resp,
          });
        }
      } catch (e) {
        DUIAppState().update<Map<String, dynamic>>("api", {
          "isLoading": false,
          "message": "Something went wrong",
          "data": null,
        });
        print("Error  : $e");
      }
    });

    addMessageHandler('exit', (e) {
      SystemNavigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DUIFactory().createInitialPage();
  }
}
