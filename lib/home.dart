import 'package:digia_ui/digia_ui.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gonest/gokwik.service.dart';

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
        print(resp);
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
  }

  @override
  Widget build(BuildContext context) {
    return DUIFactory().createInitialPage();
  }
}
