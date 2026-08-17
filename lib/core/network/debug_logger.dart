import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Centralized Debug Logger for Zabira Academy API, Auth, and Payments.
/// Redacts sensitive information (tokens, passwords, secrets, private keys, payment credentials)
/// while printing clear, actionable request & response metadata in debug mode.
class DebugLogger {
  DebugLogger._();

  static const Set<String> _sensitiveKeys = {
    'password',
    'confirm_password',
    'confirmPassword',
    'current_password',
    'new_password',
    'token',
    'access_token',
    'jwt',
    'refresh_token',
    'secret',
    'api_secret',
    'cashfree_secret',
    'razorpay_secret',
    'private_key',
    'credential',
    'authorization',
  };

  /// Sanitize a JSON map or string, replacing sensitive fields with [REDACTED]
  static dynamic sanitize(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final k = key.toString().toLowerCase();
        if (_sensitiveKeys.any((s) => k.contains(s))) {
          sanitized[key.toString()] = '[REDACTED]';
        } else if (value is Map || value is List) {
          sanitized[key.toString()] = sanitize(value);
        } else {
          sanitized[key.toString()] = value;
        }
      });
      return sanitized;
    }
    if (data is List) {
      return data.map((item) => sanitize(item)).toList();
    }
    return data;
  }

  /// Log outgoing HTTP request
  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────── [API REQUEST] ───────────────────────────');
    buffer.writeln('│ Method: $method');
    buffer.writeln('│ URL:    $uri');
    if (uri.queryParameters.isNotEmpty) {
      buffer.writeln('│ Query:  ${uri.queryParameters}');
    }
    if (body != null) {
      dynamic parsedBody = body;
      if (body is String && body.trim().startsWith('{')) {
        try {
          parsedBody = jsonDecode(body);
        } catch (_) {}
      }
      final sanitizedBody = sanitize(parsedBody);
      buffer.writeln('│ Body:   ${jsonEncode(sanitizedBody)}');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Log incoming HTTP response
  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    dynamic body,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';

    buffer.writeln('┌─────────────────────────── [API RESPONSE $icon] ───────────────────────────');
    buffer.writeln('│ Method: $method');
    buffer.writeln('│ URL:    $uri');
    buffer.writeln('│ Status: $statusCode');
    if (duration != null) {
      buffer.writeln('│ Latency: ${duration.inMilliseconds} ms');
    }

    if (body != null) {
      dynamic parsedBody = body;
      if (body is String && body.trim().startsWith('{')) {
        try {
          parsedBody = jsonDecode(body);
        } catch (_) {}
      }
      final sanitizedBody = sanitize(parsedBody);
      final bodyStr = jsonEncode(sanitizedBody);
      final displayStr = bodyStr.length > 500 ? '${bodyStr.substring(0, 500)}... (truncated)' : bodyStr;
      buffer.writeln('│ Body:   $displayStr');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Log API errors with context
  static void logError({
    required String context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────── [API ERROR ⚠️] ───────────────────────────');
    buffer.writeln('│ Context: $context');
    buffer.writeln('│ Error:   $error');
    buffer.writeln('└─────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Structured payment lifecycle stage logging.
  ///
  /// Produces output in the format:
  /// ```
  /// [PAYMENT STAGE] product_type=course | product_id=42 | order_id=1337 | stage=gateway_launch | gateway=razorpay
  /// ```
  ///
  /// Sensitive data (JWT, passwords, secrets) is automatically redacted via [sanitize].
  static void logPaymentStage({
    required String stage,
    String? productType,
    int? productId,
    int? orderId,
    String? gateway,
    Map<String, dynamic>? data,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer('[PAYMENT STAGE]');
    if (productType != null) buffer.write(' product_type=$productType');
    if (productId != null && productId > 0) buffer.write(' | product_id=$productId');
    if (orderId != null && orderId > 0) buffer.write(' | order_id=$orderId');
    if (gateway != null) buffer.write(' | gateway=$gateway');
    buffer.write(' | stage=$stage');
    if (data != null) {
      final sanitizedData = sanitize(data);
      // Redact long key-like strings (razorpay key beyond prefix)
      if (sanitizedData is Map) {
        final display = <String, dynamic>{};
        sanitizedData.forEach((key, value) {
          if (key.toString().toLowerCase().contains('key') && value is String && value.length > 8) {
            display[key.toString()] = '${value.substring(0, 6)}***';
          } else if (key.toString().toLowerCase().contains('order_id') && value is String && value.length > 10) {
            display[key.toString()] = '${value.substring(0, 10)}***';
          } else {
            display[key.toString()] = value;
          }
        });
        buffer.write(' | $display');
      } else {
        buffer.write(' | $sanitizedData');
      }
    }
    debugPrint(buffer.toString());
  }
}
