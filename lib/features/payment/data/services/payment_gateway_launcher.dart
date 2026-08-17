import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/network/debug_logger.dart';
import '../models/payment_models.dart';

class PaymentGatewayLaunchException implements Exception {
  const PaymentGatewayLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentGatewayResult {
  const PaymentGatewayResult({
    required this.gateway,
    required this.gatewayOrderId,
    this.paymentId,
    this.signature,
    this.razorpayOrderId,
    this.rawResponse,
  });

  final String gateway;
  final String gatewayOrderId;
  final String? paymentId;
  final String? signature;
  final String? razorpayOrderId;
  final dynamic rawResponse;
}

class PaymentGatewayLauncher {
  PaymentGatewayLauncher({CFPaymentGatewayService? cashfree})
      : _cashfree = cashfree ?? CFPaymentGatewayService();

  final CFPaymentGatewayService _cashfree;
  Razorpay? _razorpay;

  Future<PaymentGatewayResult> launch({
    required BuildContext context,
    required PaymentSessionModel session,
    required String title,
    required double amount,
  }) {
    switch (session.gateway.toLowerCase()) {
      case 'razorpay':
        return _launchRazorpay(session: session, title: title, amount: amount);
      case 'cashfree':
        return _launchCashfree(session: session);
      default:
        throw PaymentGatewayLaunchException('Unsupported payment gateway: ${session.gateway}.');
    }
  }

  Future<PaymentGatewayResult> _launchRazorpay({
    required PaymentSessionModel session,
    required String title,
    required double amount,
  }) {
    final missing = <String>[];
    if (session.razorpayKeyId == null || session.razorpayKeyId!.isEmpty) {
      missing.add('razorpay_key_id');
    }
    if (session.razorpayOrderId == null || session.razorpayOrderId!.isEmpty) {
      missing.add('razorpay_order_id');
    }
    final amountPaise = session.amountPaise ?? (amount * 100).round();
    if (amountPaise <= 0) {
      missing.add('amount_paise');
    }
    if (missing.isNotEmpty) {
      DebugLogger.logPaymentStage(
        stage: 'razorpay_validation_failed',
        gateway: 'razorpay',
        data: {'missing_fields': missing.join(', ')},
      );
      throw PaymentGatewayLaunchException('Unable to initialize payment gateway.');
    }

    // Log sanitized options before open()
    DebugLogger.logPaymentStage(
      stage: 'razorpay_pre_launch',
      gateway: 'razorpay',
      data: {
        'razorpay_key': session.razorpayKeyId ?? '',
        'razorpay_order_id': session.razorpayOrderId ?? '',
        'amount_paise': amountPaise,
        'currency': session.currency,
        'has_customer_name': session.customerName != null,
        'has_customer_email': session.customerEmail != null,
        'has_customer_phone': session.customerPhone != null,
      },
    );

    final completer = Completer<PaymentGatewayResult>();
    _razorpay?.clear();
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (completer.isCompleted) return;
      final paymentId = response.paymentId;
      final orderId = response.orderId ?? session.razorpayOrderId;
      final signature = response.signature;

      DebugLogger.logPaymentStage(
        stage: 'razorpay_success_callback',
        gateway: 'razorpay',
        data: {
          'payment_id': paymentId ?? 'null',
          'order_id': orderId ?? 'null',
          'has_signature': signature != null && signature.isNotEmpty,
        },
      );

      if (paymentId == null || paymentId.isEmpty || orderId == null || orderId.isEmpty || signature == null || signature.isEmpty) {
        completer.completeError(const PaymentGatewayLaunchException('Razorpay returned an incomplete payment response.'));
        return;
      }
      completer.complete(
        PaymentGatewayResult(
          gateway: 'razorpay',
          gatewayOrderId: orderId,
          paymentId: paymentId,
          signature: signature,
          razorpayOrderId: orderId,
          rawResponse: {
            'payment_id': paymentId,
            'order_id': orderId,
            'signature_present': true,
          },
        ),
      );
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      final message = response.message?.trim();
      final code = response.code;

      DebugLogger.logPaymentStage(
        stage: 'razorpay_error_callback',
        gateway: 'razorpay',
        data: {
          'error_code': code,
          'error_message': message ?? 'empty',
        },
      );

      completer.completeError(
        PaymentGatewayLaunchException(message == null || message.isEmpty ? 'Payment failed or was cancelled.' : message),
      );
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      DebugLogger.logPaymentStage(
        stage: 'razorpay_external_wallet',
        gateway: 'razorpay',
        data: {'wallet_name': response.walletName ?? 'unknown'},
      );
    });

    final options = <String, dynamic>{
      'key': session.razorpayKeyId,
      'amount': amountPaise,
      'currency': session.currency,
      'name': 'Zabira Academy',
      'description': title,
      'order_id': session.razorpayOrderId,
      'prefill': {
        if (session.customerName != null) 'name': session.customerName,
        if (session.customerEmail != null) 'email': session.customerEmail,
        if (session.customerPhone != null) 'contact': session.customerPhone,
      },
      'theme': {'color': '#D7A642'},
    };

    try {
      DebugLogger.logPaymentStage(stage: 'razorpay_open_call', gateway: 'razorpay');
      _razorpay!.open(options);
      DebugLogger.logPaymentStage(stage: 'razorpay_open_returned', gateway: 'razorpay');
    } catch (e) {
      DebugLogger.logPaymentStage(
        stage: 'razorpay_open_exception',
        gateway: 'razorpay',
        data: {'error': e.toString()},
      );
      _razorpay?.clear();
      throw PaymentGatewayLaunchException('Payment Gateway Error: $e');
    }

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => throw const PaymentGatewayLaunchException('Payment timed out before gateway confirmation.'),
    ).whenComplete(() => _razorpay?.clear());
  }

  Future<PaymentGatewayResult> _launchCashfree({required PaymentSessionModel session}) async {
    final missing = <String>[];
    if (session.paymentSessionId == null || session.paymentSessionId!.isEmpty) {
      missing.add('payment_session_id');
    }
    if (session.gatewayOrderId == null || session.gatewayOrderId!.isEmpty) {
      missing.add('gateway_order_id');
    }
    if (missing.isNotEmpty) {
      DebugLogger.logPaymentStage(
        stage: 'cashfree_validation_failed',
        gateway: 'cashfree',
        data: {'missing_fields': missing.join(', ')},
      );
      throw PaymentGatewayLaunchException('Unable to initialize payment gateway.');
    }

    DebugLogger.logPaymentStage(
      stage: 'cashfree_pre_launch',
      gateway: 'cashfree',
      data: {
        'gateway_order_id': session.gatewayOrderId ?? '',
        'environment': session.cashfreeEnv,
        'has_session_id': session.paymentSessionId != null,
      },
    );

    final completer = Completer<PaymentGatewayResult>();

    // Track whether ANY callback has fired (launch detection)
    bool callbackReceived = false;

    _cashfree.setCallback(
      (String orderId) {
        callbackReceived = true;
        if (completer.isCompleted) return;

        DebugLogger.logPaymentStage(
          stage: 'cashfree_success_callback',
          gateway: 'cashfree',
          data: {'cashfree_order_id': orderId},
        );

        completer.complete(
          PaymentGatewayResult(
            gateway: 'cashfree',
            gatewayOrderId: orderId,
            rawResponse: {'cashfree_order_id': orderId},
          ),
        );
      },
      (CFErrorResponse errorResponse, String orderId) {
        callbackReceived = true;
        if (completer.isCompleted) return;

        final message = errorResponse.getMessage()?.trim();
        DebugLogger.logPaymentStage(
          stage: 'cashfree_error_callback',
          gateway: 'cashfree',
          data: {
            'order_id': orderId,
            'error_message': message ?? 'empty',
          },
        );

        // STATE: Payment Failed — explicit error from gateway
        completer.completeError(
          PaymentGatewayLaunchException(message == null || message.isEmpty ? 'Cashfree payment failed for order $orderId.' : message),
        );
      },
    );

    try {
      final environment = session.cashfreeEnv.toLowerCase().contains('sandbox')
          ? CFEnvironment.SANDBOX
          : CFEnvironment.PRODUCTION;
      final cfSession = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(session.gatewayOrderId!)
          .setPaymentSessionId(session.paymentSessionId!)
          .build();
      final theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor('#081D3A')
          .setNavigationBarTextColor('#FFFFFF')
          .setButtonBackgroundColor('#D7A642')
          .setButtonTextColor('#081D3A')
          .build();
      final payment = CFDropCheckoutPaymentBuilder()
          .setSession(cfSession)
          .setTheme(theme)
          .build();

      DebugLogger.logPaymentStage(stage: 'cashfree_doPayment_call', gateway: 'cashfree');
      _cashfree.doPayment(payment);
      DebugLogger.logPaymentStage(stage: 'cashfree_doPayment_returned', gateway: 'cashfree');
    } on CFException catch (e) {
      // STATE: Gateway Launch Failure — SDK threw during launch
      DebugLogger.logPaymentStage(
        stage: 'cashfree_launch_exception',
        gateway: 'cashfree',
        data: {'error': e.message},
      );
      throw PaymentGatewayLaunchException('Payment Gateway Error: ${e.message}');
    } catch (e) {
      // STATE: Gateway Launch Failure — unexpected error
      DebugLogger.logPaymentStage(
        stage: 'cashfree_launch_exception',
        gateway: 'cashfree',
        data: {'error': e.toString()},
      );
      throw PaymentGatewayLaunchException('Payment Gateway Error: $e');
    }

    // STATE: Launch detection — if no callback fires within 15 seconds,
    // the gateway likely failed to open (as opposed to user still interacting).
    // This separates "gateway launch failure" from "user payment pending".
    Future<void>.delayed(const Duration(seconds: 15)).then((_) {
      if (!callbackReceived && !completer.isCompleted) {
        DebugLogger.logPaymentStage(
          stage: 'cashfree_launch_timeout',
          gateway: 'cashfree',
          data: {'seconds': 15, 'callback_received': false},
        );
        completer.completeError(
          const PaymentGatewayLaunchException('Payment Gateway Error: Cashfree checkout did not open. Please try again.'),
        );
      }
    });

    // STATE: User Payment Pending — gateway is open, user is interacting.
    // 10-minute timeout for user interaction.
    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => throw const PaymentGatewayLaunchException('Payment timed out before gateway confirmation.'),
    );
  }
}
