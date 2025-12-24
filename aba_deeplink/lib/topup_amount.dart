import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

// Payment Confirmation Screen remains the same, no changes needed
class PaymentConfirmationScreen extends StatelessWidget {
  final String amount;
  final String paymentType;

  const PaymentConfirmationScreen({
    Key? key,
    required this.amount,
    required this.paymentType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5D34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F5D34),
        title: Text(
          'Confirm Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            amount,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Method:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            paymentType,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            amount,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F5D34),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Pay now button
                ElevatedButton(
                  onPressed: () {
                    // Handle payment processing
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                        title: Text('Processing Payment'),
                        content: Text(
                          'Your payment of $amount using $paymentType is being processed.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5D34),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  String? selectedAmount;
  String? selectedPaymentType;

  // ABA Pay API details
  final String apiUrl = "https://checkout.payway.com.kh/api/payment-gateway/v1/payments/purchase";
  final String apiKey = ""; // Your API Key
  final String merchantId = "";

  String getHash(String str) {
    final key = utf8.encode(apiKey);
    final bytes = utf8.encode(str);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(bytes);
    return base64Encode(digest.bytes);
  }

  Future<void> processABADeeplink() async {
    // Extract the numeric value from the selected amount (removing the $ sign)
    final numericAmount = selectedAmount!.replaceAll('\$', '').trim();

    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final amount = "$numericAmount.00";
    const firstname = "MengHeang";
    const lastname = "Ros";
    const phone = "011375090";
    const email = 'rosmengheang168@ababank.com';

    final itemsData = [
      {'name': 'vKPoint Top-Up', 'quantity': '1', 'price': amount},
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
    final hashString =
        "$reqTime$merchantId$transactionId$amount$items$shipping$firstname$lastname$email$phone$type$paymentOption$currency$returnParams";
    final hash = getHash(hashString);

    try {
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
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> openDeepLink(String deeplink) async {
    try {
      final Uri uri = Uri.parse(deeplink);
      if (!await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If can't launch deeplink, try to open app store
        const playStoreUrl =
            'https://play.google.com/store/apps/details?id=com.paygo24.ibank';
        const appStoreUrl =
            'https://itunes.apple.com/al/app/aba-mobile-bank/id968860649?mt=8';

        if (Platform.isAndroid) {
          await launchUrl(Uri.parse(playStoreUrl));
        } else if (Platform.isIOS) {
          await launchUrl(Uri.parse(appStoreUrl));
        } else {
          throw 'Could Not Open Play Store or DeepLink';
        }
      }
    } catch (e) {
      print('Error opening deeplink: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open ABA Pay. Please ensure the app is installed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5D34),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F5D34),
        title: Text(
          'Top-Up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Card
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5D34),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        '0000000901',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Registered',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/logos/vkirirom_logo.png',
                                    width: 100,
                                    height: 40,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Available Balance:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '0000000901 vKPoint',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F5D34),
                                      border: Border.all(color: Colors.white30),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'Student',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Buying Balance: 0 vKPoint',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Choose Amount Section
                        const Text(
                          'Choose amount',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Amount Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildAmountButton('\$5'),
                            _buildAmountButton('\$10'),
                            _buildAmountButton('\$20'),
                            _buildAmountButton('\$50'),
                            _buildAmountButton('\$100'),
                            _buildAmountButton('\$200'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Choose Payment Type Section
                        const Text(
                          'Choose payment type',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ABA Pay Option
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedPaymentType = 'ABA Pay';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                selectedPaymentType == 'ABA Pay'
                                    ? const Color(0xFF0F5D34)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00539B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Center(
                                        child: Text(
                                          'ABA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'ABA Pay',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tap to pay with ABA Mobile',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (selectedPaymentType == 'ABA Pay')
                                  Icon(
                                    Icons.check_circle,
                                    color: const Color(0xFF0F5D34),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card Payment Option
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedPaymentType = 'Card';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                selectedPaymentType == 'Card'
                                    ? const Color(0xFF0F5D34)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00789A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.credit_card,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Card',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'VISA, MasterCard, Union pay',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (selectedPaymentType == 'Card')
                                  Icon(
                                    Icons.check_circle,
                                    color: const Color(0xFF0F5D34),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed:
                  selectedAmount != null && selectedPaymentType != null
                      ? () {
                    // Handle different payment types
                    if (selectedPaymentType == 'ABA Pay') {
                      // Process ABA Pay deeplink
                      processABADeeplink();
                    } else {
                      // Navigate to card payment confirmation screen
                      navigateToPaymentScreen(context);
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5D34),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountButton(String amount) {
    bool isSelected = selectedAmount == amount;

    return InkWell(
      onTap: () {
        setState(() {
          selectedAmount = amount;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
          isSelected
              ? const Color(0xFF0F5D34).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5D34) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? const Color(0xFF0F5D34) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void navigateToPaymentScreen(BuildContext context) {
    if (selectedPaymentType == 'Card') {
      // Extract numeric amount
      final numericAmount = selectedAmount!.replaceAll('\$', '').trim();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ABAWebView(amount: numericAmount, firstname: "MengHeang", lastname: 'Ros', email: 'rosmengheang168@ababank.com', phone: '011375090'),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            amount: selectedAmount!,
            paymentType: selectedPaymentType!,
          ),
        ),
      );
    }
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
