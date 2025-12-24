import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:aba_deeplink/map/views/full_map_view.dart';
import 'package:aba_deeplink/views/face_rec_auth.dart';
import 'package:aba_deeplink/views/homepage.dart';
import 'package:aba_deeplink/views/mainscreen.dart';
import 'package:aba_deeplink/views/simple_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

// final String apiUrl = "https://checkout.payway.com.kh/api/payment-gateway/v1/payments/purchase";
// final String apiKey = "6f342c2a-1b53-47f4-9320-65a1f51d3e7f"; // Your API Key
// final String merchantId = "kitvkirirom";

class ABA_DEEPLINK extends StatefulWidget {
  const ABA_DEEPLINK({super.key});

  @override
  State<ABA_DEEPLINK> createState() => _ABA_DEEPLINKState();
}

class _ABA_DEEPLINKState extends State<ABA_DEEPLINK> {
  final String apiUrl = "https://checkout.payway.com.kh/api/payment-gateway/v1/payments/purchase";
  final String apiKey = ""; // Your API Key
  final String merchantId = ""; // Your Merchant ID

  String getHash(String str) {
    final key = utf8.encode(apiKey);
    final bytes = utf8.encode(str);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(bytes);
    return base64Encode(digest.bytes);
  }

  Future<void> checkoutABA() async {
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    const amount = "10.00";
    const firstname = "MengHeang";
    const lastname = "Ros";
    const phone = "011375090";
    const email = 'rosmengheang168@ababank.com';

    final itemsData = [
      {'name': 'test1', 'quantity': '1', 'price': '10.00'},
      {'name': 'test2', 'quantity': '1', 'price': '10.00'},
    ];

    final jsonString = jsonEncode(itemsData);
    final bytes = utf8.encode(jsonString);
    final items = base64Encode(bytes);

    const shipping = '0.00';
    const returnParams = "HelloWorld";
    const type = 'purchase';
    const currency = 'USD';
    const paymentOption = 'abapay_deeplink';

    final reqTime = DateTime.now().millisecondsSinceEpoch.toString();
    final hashString = "$reqTime$merchantId$transactionId$amount$items$shipping$firstname$lastname$email$phone$type$paymentOption$currency$returnParams";
    final hash = getHash(hashString);

    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'hash': hash,
        'tran_id': transactionId,
        'amount': amount,
        'firstname': firstname,
        'lastname': lastname,
        'phone': phone,
        'email': email,
        'items': items,
        'return_params': returnParams,
        'shipping': shipping,
        'currency': currency,
        'type': type,
        'merchant_id': merchantId,
        'req_time': reqTime,
        'payment_option': paymentOption,
      },
    );

    if (response.statusCode == 200) {
      print('Payment Request Sent Successfully');
      final deeplink = jsonDecode(response.body)['abapay_deeplink'];
      openDeepLink(deeplink);
    } else {
      print('Failed To Send Payment Request');
    }
  }

  Future<void> openDeepLink(String deeplink) async {
    try {
      if (!await canLaunchUrl(Uri.parse(deeplink))) {
        print("Can Launch");
        await launchUrl(Uri.parse(deeplink));
      } else {
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.paygo24.ibank';
        const appStoreUrl = 'https://itunes.apple.com/al/app/aba-mobile-bank/id968860649?mt=8';

        if (Platform.isAndroid) {
          print("isAndroid");
          await launchUrl(Uri.parse(playStoreUrl));
        } else if (Platform.isIOS) {
          await launchUrl(Uri.parse(appStoreUrl));
        } else {
          throw 'Could Not Open Play Store or DeepLink';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABA DEEPLINK TESTING'),
        leading: IconButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_) => MapView()));}, icon: Icon(Icons.map_outlined)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('10.00\$'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkoutABA,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Checkout ABA'),
            ),
            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ABAWebView(amount: '10', firstname: 'MengHeang', lastname: 'Ros', email: 'rosmengheang168@ababank.com', phone: '011375090'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Checkout Cards'),
            ),
          ],
        ),
      ),
    );
  }
}





class ABAWebView extends StatefulWidget {
  const ABAWebView({
    super.key,
    required this.amount,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
  });

  final String amount;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;

  @override
  State<ABAWebView> createState() => _ABAWebViewState();
}

class _ABAWebViewState extends State<ABAWebView> {
  bool _isLoading = true;
  late final WebViewController _controller;

  // PayWay Configuration - Replace with your actual values
  final String apiUrl = "https://checkout.payway.com.kh/api/payment-gateway/v1/payments/purchase";
  final String publicKey = ""; // Your API Key
  final String merchantId = ""; // Your Merchant ID// Your public key here
  final String returnUrl = base64Encode(utf8.encode('http://your-return-url.com'));
  final String continueSuccessUrl = "https://your-success-url.com";
  final String paymentOption = "cards";
  final String viewType = "hosted";

  late String reqTime;
  late String tranId;
  late String hash;
  late String formViewABA;

  @override
  void initState() {
    super.initState();
    reqTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    tranId = reqTime; // Using reqTime as tranId like in the working example
    _generateHash();
    _generateFormView();
    _initializeWebView();
  }

  void _generateHash() {
    try {
      // Concatenate values in exact order as working example
      final String baseString = reqTime +
          merchantId +
          tranId +
          widget.amount +
          widget.firstname +
          paymentOption +
          returnUrl +
          continueSuccessUrl;

      print('Base string for hash: $baseString'); // For debugging

      String hashHmacSha512(message, publicKey) {
        var key = utf8.encode(publicKey);
        var bytes = utf8.encode(message);
        var digest = Hmac(sha512, key).convert(bytes);
        return base64Encode(digest.bytes);
      }

      // Use the hashHmacSha512 function from your hash_helper.dart
      hash = hashHmacSha512(baseString, publicKey);
      print('Generated hash: $hash'); // For debugging
    } catch (e) {
      print('Error generating hash: $e');
      hash = '';
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation to: ${request.url}');
            if (request.url == continueSuccessUrl) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(formViewABA);
  }

  void _generateFormView() {
    formViewABA = """
      <html>
        <body>
          <form action="$apiUrl" method="post" enctype="multipart/form-data">
            <input type="hidden" id="req_time" name="req_time" value="$reqTime">
            <input type="hidden" id="merchant_id" name="merchant_id" value="$merchantId">
            <input type="hidden" id="tran_id" name="tran_id" value="$tranId">
            <input type="hidden" id="firstname" name="firstname" value="${widget.firstname}">
            <input type="hidden" id="amount" name="amount" value="${widget.amount}">
            <input type="hidden" id="payment_option" name="payment_option" value="$paymentOption">
            <input type="hidden" id="return_url" name="return_url" value="$returnUrl">
            <input type="hidden" id="continue_success_url" name="continue_success_url" value="$continueSuccessUrl">
            <input type="hidden" id="view_type" name="view_type" value="$viewType">
            <input type="hidden" id="hash" name="hash" value="$hash">
            <input type="submit" id="submit_form" style="display: none;">
          </form>
          <script src="https://checkout.payway.com.kh/plugins/checkout2-0.js"></script>
          <script>
            document.getElementById('submit_form').click();
          </script>
        </body>
      </html>
    """;
  }

  void showAlertDialog({
    required BuildContext context,
    required String title,
    required String message,
    String dismissText = 'Close',
    VoidCallback? onDismissed,
    List<Widget>? actions,
  }) {
    Theme.of(context).platform == TargetPlatform.iOS
        ? showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismissed != null) onDismissed();
                },
                child: Text(
                  dismissText,
                  style: TextStyle(color: actions != null ? Colors.red : null),
                ),
              ),
              ...?actions,
            ],
          );
        })
        : showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            if (onDismissed != null) onDismissed();

            return true;
          },
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismissed != null) onDismissed();
                },
                child: Text(
                  dismissText,
                  style: TextStyle(color: actions != null ? Colors.red : null),
                ),
              ),
              ...?actions,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Color.fromRGBO(11, 127, 23, 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          "Top Up",
          style: TextStyle(
            color: Color.fromRGBO(11, 127, 23, 1),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            showAlertDialog(
                context: context,
                title: "Top-up Failed",
                message: "The transaction was canceled"
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}




// class ABAWebView extends StatefulWidget {
//   const ABAWebView({
//     super.key,
//     required this.amount,
//     required this.firstname,
//     required this.lastname,
//     required this.email,
//     required this.phone,
//   });
//
//   final String amount;
//   final String firstname;
//   final String lastname;
//   final String email;
//   final String phone;
//
//   @override
//   State<ABAWebView> createState() => _ABAWebViewState();
// }
//
// class _ABAWebViewState extends State<ABAWebView> {
//   bool _isLoading = true;
//   late final WebViewController _controller;
//
//   // PayWay Configuration - Replace with your actual values
//   final String apiUrl = "https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase";
//   final String merchantId = "ec438866";
//   final String apiKey = "3bfca23cdc0947d48fd4a81e2c4ee1abd0a47baf";
//   final String returnUrl = "https://your-return-url.com";
//   final String continueSuccessUrl = "https://your-success-url.com";
//
//   late String reqTime;
//   late String tranId;
//   late String hash;
//   late String formViewABA;
//
//   @override
//   void initState() {
//     super.initState();
//     reqTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
//     tranId = 'TRAN_${reqTime}';  // Create a unique transaction ID
//     _generateHash();
//     _generateFormView();
//     _initializeWebView();
//   }
//
//   void _generateHash() {
//     try {
//       // Create the base string exactly as specified by ABA PayWay
//       final StringBuffer buffer = StringBuffer();
//       buffer.write(reqTime);
//       buffer.write(merchantId);
//       buffer.write(tranId);
//       buffer.write(widget.amount);
//       buffer.write(widget.firstname);
//       buffer.write(widget.lastname);
//       buffer.write(widget.email);
//       buffer.write(widget.phone);
//       buffer.write("cards");
//       buffer.write(returnUrl);
//       buffer.write(continueSuccessUrl);
//
//       final String baseString = buffer.toString();
//       print('Base string for hash: $baseString'); // For debugging
//
//       // Create HMAC SHA512
//       final key = utf8.encode(apiKey);
//       final bytes = utf8.encode(baseString);
//       final hmac = Hmac(sha512, key);
//       final digest = hmac.convert(bytes);
//
//       hash = digest.toString().toUpperCase();
//       print('Generated hash: $hash'); // For debugging
//     } catch (e) {
//       print('Error generating hash: $e');
//       hash = '';
//     }
//   }
//
//   void _initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//             });
//           },
//           onNavigationRequest: (NavigationRequest request) {
//             print('Navigation to: ${request.url}'); // For debugging
//             if (request.url == continueSuccessUrl) {
//               Navigator.of(context).pop(true);
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadHtmlString(formViewABA);
//   }
//
//   void _generateFormView() {
//     // Create items JSON
//     final items = [
//       {
//         'name': 'Payment',
//         'quantity': '1',
//         'price': widget.amount
//       }
//     ];
//     final itemsJson = jsonEncode(items);
//
//     formViewABA = """
//       <!DOCTYPE html>
//       <html>
//         <head>
//           <meta charset="UTF-8">
//           <meta name="viewport" content="width=device-width, initial-scale=1.0">
//         </head>
//         <body>
//           <form id="paymentForm" action="$apiUrl" method="POST" enctype="multipart/form-data">
//             <input type="hidden" name="req_time" value="$reqTime">
//             <input type="hidden" name="merchant_id" value="$merchantId">
//             <input type="hidden" name="tran_id" value="$tranId">
//             <input type="hidden" name="amount" value="${widget.amount}">
//             <input type="hidden" name="items" value='$itemsJson'>
//             <input type="hidden" name="firstname" value="${widget.firstname}">
//             <input type="hidden" name="lastname" value="${widget.lastname}">
//             <input type="hidden" name="email" value="${widget.email}">
//             <input type="hidden" name="phone" value="${widget.phone}">
//             <input type="hidden" name="payment_option" value="cards">
//             <input type="hidden" name="return_url" value="$returnUrl">
//             <input type="hidden" name="continue_success_url" value="$continueSuccessUrl">
//             <input type="hidden" name="currency" value="USD">
//             <input type="hidden" name="hash" value="$hash">
//           </form>
//           <script src="https://checkout.payway.com.kh/plugins/checkout2-0.js"></script>
//           <script>
//             window.onload = function() {
//               console.log('Form data:', {
//                 req_time: '$reqTime',
//                 merchant_id: '$merchantId',
//                 tran_id: '$tranId',
//                 hash: '$hash'
//               });
//               document.getElementById('paymentForm').submit();
//             }
//           </script>
//         </body>
//       </html>
//     """;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ABA PayWay Payment'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
// }