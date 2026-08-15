/// Zabira Academy — Payment Models
/// Matches official OpenAPI specifications for `/payments/*` endpoints.
library;

class PaymentSessionModel {
  const PaymentSessionModel({
    required this.orderId,
    required this.gateway,
    required this.productType,
    this.sessionId,
    this.gatewayOrderId,
    this.amount = 0.0,
    this.currency = 'INR',
    this.checkoutUrl,
    this.keyId,
    this.rawResponse = const {},
  });

  final int orderId;
  final String gateway;
  final String productType;
  final String? sessionId;
  final String? gatewayOrderId;
  final double amount;
  final String currency;
  final String? checkoutUrl;
  final String? keyId;
  final Map<String, dynamic> rawResponse;

  factory PaymentSessionModel.fromJson(Map<String, dynamic> json, {required int orderId, required String productType}) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final rawAmount = data['amount'] ?? data['total_amount'] ?? data['price'] ?? 0;
    final amount = double.tryParse(rawAmount.toString()) ?? 0.0;

    return PaymentSessionModel(
      orderId: int.tryParse((data['order_id'] ?? orderId).toString()) ?? orderId,
      gateway: data['gateway']?.toString() ?? 'cashfree',
      productType: productType,
      sessionId: data['session_id']?.toString() ?? data['id']?.toString() ?? data['payment_session_id']?.toString(),
      gatewayOrderId: data['gateway_order_id']?.toString() ?? data['order_id']?.toString() ?? data['razorpay_order_id']?.toString(),
      amount: amount,
      currency: data['currency']?.toString() ?? 'INR',
      checkoutUrl: data['checkout_url']?.toString() ?? data['payment_url']?.toString(),
      keyId: data['key_id']?.toString() ?? data['key']?.toString(),
      rawResponse: json,
    );
  }
}

class PaymentVerificationResult {
  const PaymentVerificationResult({
    required this.isSuccess,
    required this.message,
    this.orderId,
    this.transactionId,
    this.enrollmentConfirmed = false,
    this.rawResponse = const {},
  });

  final bool isSuccess;
  final String message;
  final int? orderId;
  final String? transactionId;
  final bool enrollmentConfirmed;
  final Map<String, dynamic> rawResponse;

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true || json['status'] == 'success' || json['status'] == 'verified';
    final msg = json['message']?.toString() ?? (success ? 'Payment verified successfully.' : 'Payment verification failed.');

    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    return PaymentVerificationResult(
      isSuccess: success,
      message: msg,
      orderId: int.tryParse(data['order_id']?.toString() ?? ''),
      transactionId: data['transaction_id']?.toString() ?? data['payment_id']?.toString(),
      enrollmentConfirmed: data['enrollment_confirmed'] == true || data['enrolled'] == true || success,
      rawResponse: json,
    );
  }
}

class PaymentGatewayInfo {
  const PaymentGatewayInfo({
    required this.id,
    required this.code,
    required this.name,
    this.icon,
    this.isActive = true,
    this.isConfigured = true,
    this.isRecommended = false,
    this.features = const ['UPI', 'Credit Cards', 'Debit Cards', 'Net Banking', 'Wallets'],
    this.tagline = '',
  });

  final int id;
  final String code; // 'cashfree', 'razorpay'
  final String name;
  final String? icon;
  final bool isActive;
  final bool isConfigured;
  final bool isRecommended;
  final List<String> features;
  final String tagline;

  factory PaymentGatewayInfo.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] ?? [];
    final featList = (rawFeatures is List)
        ? rawFeatures.map((e) => e.toString()).toList()
        : const ['UPI', 'Credit Cards', 'Debit Cards', 'Net Banking', 'Wallets'];

    return PaymentGatewayInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? (json['id']?.toString().hashCode ?? 0),
      code: json['id']?.toString() ?? json['code']?.toString() ?? 'cashfree',
      name: json['label']?.toString() ?? json['name']?.toString() ?? (json['id']?.toString() == 'cashfree' ? 'Cashfree' : 'Razorpay'),
      icon: json['icon']?.toString() ?? json['logo']?.toString(),
      isActive: json['enabled'] == true || json['is_active'] == true || json['status'] == 'active' || json['active'] == 1,
      isConfigured: json['configured'] != false,
      isRecommended: json['recommended'] == true || json['is_recommended'] == true,
      features: featList,
      tagline: json['tagline']?.toString() ?? '',
    );
  }
}

class MyOrderItem {
  const MyOrderItem({
    required this.orderId,
    required this.title,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    this.date,
    this.productType = 'course',
    this.invoiceNumber,
    this.invoiceUrl,
  });

  final int orderId;
  final String title;
  final double amount;
  final String status;
  final String paymentStatus;
  final DateTime? date;
  final String productType;
  final String? invoiceNumber;
  final String? invoiceUrl;

  bool get isPaid => paymentStatus.toLowerCase() == 'paid' || status.toLowerCase() == 'completed';

  factory MyOrderItem.fromJson(Map<String, dynamic> json) {
    return MyOrderItem(
      orderId: int.tryParse(json['id']?.toString() ?? json['order_id']?.toString() ?? '0') ?? 0,
      title: json['item_name']?.toString() ?? json['title']?.toString() ?? json['product_name']?.toString() ?? 'Order Item',
      amount: double.tryParse((json['total_amount'] ?? json['amount'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? json['status']?.toString() ?? 'pending',
      date: DateTime.tryParse(json['created_at']?.toString() ?? json['order_date']?.toString() ?? ''),
      productType: json['product_type']?.toString() ?? 'course',
      invoiceNumber: json['invoice_number']?.toString(),
      invoiceUrl: json['invoice_url']?.toString() ?? json['invoice_pdf']?.toString(),
    );
  }
}
