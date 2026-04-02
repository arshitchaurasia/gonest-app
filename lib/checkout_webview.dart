import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutWebView extends StatefulWidget {
  final String url;

  const CheckoutWebView({super.key, required this.url});

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController controller;

  bool isLoading = true; // 🔥 controls loader

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      // ✅ JS Channel (for iframe messages)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (message) {
          print("RAW MESSAGE: ${message.message}");

          try {
            var data = message.message;

            // 🔥 Handle double-encoded JSON
            if (data.startsWith('"')) {
              data = jsonDecode(data);
            }

            final parsed = jsonDecode(data);
            print("Parsed Message: $parsed");

            // 🔥 Optional: handle events if GoKwik sends
            if (parsed["event"] == "payment_success") {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment Success 🎉")),
              );
            }

          } catch (e) {
            print("Non JSON message");
          }
        },
      )

      ..setNavigationDelegate(
        NavigationDelegate(
          // 🔥 When page loads → hide loader
          onPageFinished: (url) async {
            print("Page Loaded: $url");

            if (isLoading) {
              setState(() {
                isLoading = false;
              });
            }

            // 🔥 Inject JS listener
            await controller.runJavaScript("""
              window.addEventListener("message", function(event) {
                try {
                  FlutterChannel.postMessage(JSON.stringify(event.data));
                } catch (e) {
                  FlutterChannel.postMessage("error");
                }
              });
            """);
          },

          onNavigationRequest: (request) {
            final url = request.url;

            print("URL: $url");

            // ✅ Success detection (keep this ALWAYS)
            if (url.contains("thank_you") ||
                url.contains("order-success")) {

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Order placed successfully"),
                ),
              );

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )

      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Stack(
        children: [
          // ✅ WebView (shown after load)
          if (!isLoading)
            WebViewWidget(controller: controller),

          // ✅ Loader (shown first)
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}