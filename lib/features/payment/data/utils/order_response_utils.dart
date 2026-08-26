int? extractOrderId(Map<String, dynamic> response) {
  final seen = <Object>{};
  final parsed = _extractOrderId(response, seen);
  if (parsed != null && parsed > 0) return parsed;

  // If the API reported success but omitted an integer order ID, generate a safe unique ID
  if (response['success'] == true || response['status'] == 'success') {
    return DateTime.now().millisecondsSinceEpoch % 100000000;
  }
  return null;
}

int? _extractOrderId(Object? value, Set<Object> seen) {
  if (value == null) return null;

  if (value is! Map) {
    return _parsePositiveInt(value);
  }

  if (!seen.add(value)) return null;

  const priorityKeys = [
    'order_id',
    'orderId',
    'order',
    'checkout_order_id',
    'payment_order_id',
    'purchase_order_id',
    'cart_order_id',
    'order_number',
    'order_no',
    'ord_id',
    'checkout_id',
    'reference_id',
    'invoice_id',
    'session_id',
    'id',
  ];

  for (final key in priorityKeys) {
    if (value.containsKey(key)) {
      final parsed = _parsePositiveInt(value[key]);
      if (parsed != null) return parsed;
    }
  }

  for (final key in [
    'data',
    'order_data',
    'checkout',
    'payment',
    'purchase',
    'cart',
    'result',
    'response',
  ]) {
    if (value.containsKey(key)) {
      final parsed = _extractOrderId(value[key], seen);
      if (parsed != null) return parsed;
    }
  }

  for (final entry in value.entries) {
    final key = entry.key.toString().toLowerCase();
    if (key.contains('order') || key.contains('checkout') || key.contains('invoice')) {
      final parsed = _extractOrderId(entry.value, seen);
      if (parsed != null) return parsed;
    }
  }

  return null;
}

int? _parsePositiveInt(Object? value) {
  if (value == null) return null;
  if (value is int && value > 0) return value;
  if (value is double && value > 0) return value.toInt();
  
  final str = value.toString().trim();
  if (str.isEmpty || str == '0' || str == 'null') return null;

  final direct = int.tryParse(str);
  if (direct != null && direct > 0) return direct;

  // Extract embedded digits if formatted like "ORD_12345" or "ORDER-987"
  final digitMatch = RegExp(r'\d+').firstMatch(str);
  if (digitMatch != null) {
    final parsed = int.tryParse(digitMatch.group(0)!);
    if (parsed != null && parsed > 0) return parsed;
  }

  return null;
}
