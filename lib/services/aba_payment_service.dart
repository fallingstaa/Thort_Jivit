// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_payway/flutter_payway.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ABAPaymentService {
  // PayWay merchant configuration (sandbox by default)
  static const String _merchantId = "ec463100";
  static const String _merchantApiKey =
      "88b3bf9165ef20f093125e63fa0dae8aa71167a1";
  static const String _merchantApiName = "thort_jivit";
  static const String _baseApiUrl = "https://checkout-sandbox.payway.com.kh";
  static const String _refererDomain = "https://checkout-sandbox.payway.com.kh";

  static final PaywayTransactionService _service = PaywayTransactionService(
    merchant: PaywayMerchant(
      merchantID: _merchantId,
      merchantApiKey: _merchantApiKey,
      merchantApiName: _merchantApiName,
      baseApiUrl: _baseApiUrl,
      refererDomain: _refererDomain,
    ),
  );

  /// Generate HMAC SHA-512 hash for transaction check
  static String _generateHash(
    String reqTime,
    String merchantId,
    String tranId,
  ) {
    final key = utf8.encode(_merchantApiKey);
    final data = utf8.encode(reqTime + merchantId + tranId);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(data);
    return base64Encode(digest.bytes);
  }

  /// Check transaction status using ABA PayWay API
  /// Returns: {'success': bool, 'status': String, 'message': String}
  /// Status values: 'success', 'pending', 'failed', 'error'
  static Future<Map<String, dynamic>> checkTransactionStatus(
    String tranId,
  ) async {
    try {
      // Generate request time in UTC format: YYYYMMDDHHmmss
      final now = DateTime.now().toUtc();
      final reqTime = DateFormat('yyyyMMddHHmmss').format(now);

      // Generate hash
      final hash = _generateHash(reqTime, _merchantId, tranId);

      // Prepare request body
      final requestBody = jsonEncode({
        'req_time': reqTime,
        'merchant_id': _merchantId,
        'tran_id': tranId,
        'hash': hash,
      });

      foundation.debugPrint('[ABA_PAYMENT] Checking transaction: $tranId');
      foundation.debugPrint('[ABA_PAYMENT] Request time: $reqTime');

      // Make API call
      final response = await http.post(
        Uri.parse(
          '$_baseApiUrl/api/payment-gateway/v1/payments/check-transaction-2',
        ),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      foundation.debugPrint(
        '[ABA_PAYMENT] Check transaction response: ${response.statusCode}',
      );
      foundation.debugPrint('[ABA_PAYMENT] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Extract nested status object
        final statusObj = responseData['status'] as Map<String, dynamic>?;
        final dataObj = responseData['data'] as Map<String, dynamic>?;

        // Get status code and message from status object
        final code = statusObj?['code'] as String?;
        final message = statusObj?['message'] as String?;

        // Get payment status from data object
        final paymentStatus = dataObj?['payment_status'] as String?;
        final paymentStatusCode = dataObj?['payment_status_code'] as int?;

        foundation.debugPrint(
          '[ABA_PAYMENT] Parsed - code: $code, payment_status: $paymentStatus, payment_status_code: $paymentStatusCode',
        );

        // Transaction is successful if:
        // 1. Status code is "00" or "0" (success)
        // 2. Payment status is "APPROVED"
        // 3. Payment status code is 0 (approved)
        final isSuccess =
            (code != null &&
                (code == '000' ||
                    code == '00' ||
                    code == '0' ||
                    code.startsWith('0'))) ||
            (paymentStatus != null &&
                paymentStatus.toUpperCase() == 'APPROVED') ||
            (paymentStatusCode != null && paymentStatusCode == 0);

        if (isSuccess) {
          return {
            'success': true,
            'status': 'success',
            'message': message ?? paymentStatus ?? 'Payment successful',
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'status': 'failed',
            'message': message ?? paymentStatus ?? 'Payment failed or pending',
            'data': responseData,
          };
        }
      } else {
        foundation.debugPrint(
          '[ABA_PAYMENT] Check transaction failed: ${response.statusCode}',
        );
        return {
          'success': false,
          'status': 'error',
          'message':
              'Failed to check transaction status: ${response.statusCode}',
        };
      }
    } catch (e) {
      foundation.debugPrint('[ABA_PAYMENT] Check transaction error: $e');
      return {
        'success': false,
        'status': 'error',
        'message': 'Error checking transaction: $e',
      };
    }
  }

  static PaywayCreateTransaction _buildTransaction({
    required double amount,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required List<Map<String, String>> itemsData,
    required PaywayPaymentOption option,
    String? returnUrl,
    String? continueSuccessUrl,
    double shipping = 0.0,
  }) {
    final items =
        itemsData
            .map(
              (item) => PaywayTransactionItem(
                name: item["name"] ?? "Item",
                quantity: double.tryParse(item["quantity"] ?? "1") ?? 1,
                price: double.tryParse(item["price"] ?? "0") ?? 0,
              ),
            )
            .toList();

    return PaywayCreateTransaction(
      tranId: _service.uniqueTranID(),
      reqTime: _service.uniqueReqTime(),
      amount: amount,
      items: items,
      firstname: firstName,
      lastname: lastName,
      phone: phone,
      email: email,
      option: option,
      shipping: shipping,
      returnUrl: returnUrl,
      continueSuccessUrl: continueSuccessUrl,
      currency: PaywayTransactionCurrency.USD,
    );
  }

  /// Create a PayWay deeplink payment (ABA Mobile).
  /// Returns: {'deeplink': String?, 'tranId': String} or null if failed
  static Future<Map<String, dynamic>?> createDeeplinkPayment({
    required String amount,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required List<Map<String, String>> itemsData,
    String? returnUrl,
    String? continueSuccessUrl,
  }) async {
    final parsedAmount = double.tryParse(amount) ?? 0;
    final transaction = _buildTransaction(
      amount: parsedAmount,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      itemsData: itemsData,
      option: PaywayPaymentOption.abapay_deeplink,
      returnUrl: returnUrl,
      continueSuccessUrl: continueSuccessUrl,
    );

    // Get transaction ID before creating transaction
    final tranId = transaction.tranId;

    try {
      final response = await _service.createTransaction(
        transaction: transaction,
        enabledLogger: true,
      );

      final code = response.status?.code;
      final message = response.status?.message;
      final deeplink = response.abapayDeeplink;
      foundation.debugPrint(
        "PayWay deeplink response: code=$code, msg=$message, deeplink=$deeplink, tranId=$tranId, appStore=${response.appStore}, playStore=${response.playStore}",
      );

      final isSuccess = () {
        if (deeplink == null) return false;
        if (code == null) return true;
        final normalized = code.toString();
        return normalized == "0" ||
            normalized == "00" ||
            normalized.startsWith("0");
      }();

      if (isSuccess && deeplink != null) {
        return {'deeplink': deeplink, 'tranId': tranId};
      }

      foundation.debugPrint(
        "PayWay deeplink failed: ${message ?? response.description}",
      );
      return null;
    } catch (error) {
      foundation.debugPrint("PayWay deeplink error: $error");
      return null;
    }
  }

  /// Generate checkout URI for card / PayWay web payment.
  /// Returns: {'uri': Uri, 'tranId': String}
  static Future<Map<String, dynamic>> generateCardCheckoutUri({
    required String amount,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? returnUrl,
    String? continueSuccessUrl,
  }) async {
    final parsedAmount = double.tryParse(amount) ?? 0;
    final transaction = _buildTransaction(
      amount: parsedAmount,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      itemsData: const [
        {"name": "Card charge", "quantity": "1", "price": "0"},
      ],
      option: PaywayPaymentOption.cards,
      returnUrl: returnUrl,
      continueSuccessUrl: continueSuccessUrl,
    );

    // This returns a Future<Uri>, so we must await it here
    final uri = await _service.generateTransactionCheckoutURI(
      transaction: transaction,
    );

    return {'uri': uri, 'tranId': transaction.tranId};
  }

  static Future<void> launchDeepLink(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.paygo24.ibank';
      const appStoreUrl =
          'https://itunes.apple.com/al/app/aba-mobile-bank/id968860649?mt=8';
      if (Platform.isAndroid) {
        await launchUrl(
          Uri.parse(playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (Platform.isIOS) {
        await launchUrl(
          Uri.parse(appStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }
}
