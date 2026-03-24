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
        final resp = await GokwikServices.sendOtp(
          (event.payload as Map<String, dynamic>)['phone'],
        );
      } catch (e) {
        print("Error  : $e");
      }
    });

    // Handler to verify OTP.

    addMessageHandler('verifyOTP', (event) async {
      final phone = (event.payload as Map<String, dynamic>)["phone"];
      final otp = (event.payload as Map<String, dynamic>)["otp"];

      if (phone == null || otp == null) {
        print("Phone and OTP is required");
        return;
      }

      try {
        final resp = await GokwikServices.verifyOtp(phone, int.parse(otp));

        if (resp["data"]["otp_verified"]) {
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
      final merchantId = (event.payload as Map<String, dynamic>)["merchant_id"];
      final merchantName =
          (event.payload as Map<String, dynamic>)["merchant_name"];

      print("Merchant Name : $merchantName");
      print("Merchant ID : $merchantId");

      if (merchantId == null) {
        print("Merchant ID is required");
        return;
      }

      try {
        final resp = await GokwikItemServices.getMerchantCollections(
          merchantId,
          merchantName,
        );

        Navigator.of(context).push(
          DUIFactory().createPageRoute("brand_page-5wJ4NG", {"brand": resp}),
        );
      } catch (e) {
        print("Error  : $e");
      }
    });

    addMessageHandler('getCollectionProducts', (event) async {

      final merchantId = (event.payload as Map<String, dynamic>)["merchant_id"];
      final collectionId =
          (event.payload as Map<String, dynamic>)["collection_id"];
      final collectionName =
          (event.payload as Map<String, dynamic>)["collection_name"];

      print("Collection ID : $collectionId");

      if (collectionId == null || merchantId == null) {
        print("Collection ID and Merchant ID is required");
        return;
      }

      try {
        final resp = await GokwikItemServices.getCollectionProducts(
          merchantId,
          collectionId,
          collectionName
        );

        Navigator.of(context).push(
          DUIFactory().createPageRoute("collection_results-5XrEMK", {
            "collection": resp,
          }),
        );
      } catch (e) {
        print("Error  : $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DUIFactory().createInitialPage();
  }
}
