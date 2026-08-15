/// Zabira Academy — Payment Plans & EMI Model
/// Matches official OpenAPI specifications for `/payments/payment_plans.php`.
class PaymentPlansData {
  const PaymentPlansData({
    this.currency = 'INR',
    this.hasFlexiblePlans = false,
    this.originalPrice = 0.0,
    this.effectivePrice = 0.0,
    this.options = const [],
  });

  final String currency;
  final bool hasFlexiblePlans;
  final double originalPrice;
  final double effectivePrice;
  final List<PaymentPlanOption> options;

  PaymentPlanOption? get fullPlan =>
      options.cast<PaymentPlanOption?>().firstWhere((o) => o?.isFull == true, orElse: () => null);

  PaymentPlanOption? get monthlyPlan =>
      options.cast<PaymentPlanOption?>().firstWhere((o) => o?.isMonthly == true, orElse: () => null);

  factory PaymentPlansData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? (json['data']['payment_plans'] is Map<String, dynamic>
            ? json['data']['payment_plans'] as Map<String, dynamic>
            : json['data'] as Map<String, dynamic>)
        : (json['payment_plans'] is Map<String, dynamic>
            ? json['payment_plans'] as Map<String, dynamic>
            : json);

    final rawOptions = data['options'] ?? [];
    List<PaymentPlanOption> opts = [];
    if (rawOptions is List) {
      opts = rawOptions
          .whereType<Map<String, dynamic>>()
          .map((o) => PaymentPlanOption.fromJson(o))
          .toList();
    }

    return PaymentPlansData(
      currency: data['currency']?.toString() ?? 'INR',
      hasFlexiblePlans: data['has_flexible_plans'] == true,
      originalPrice: double.tryParse(data['original_price']?.toString() ?? '0') ?? 0.0,
      effectivePrice: double.tryParse(data['effective_price']?.toString() ?? '0') ?? 0.0,
      options: opts,
    );
  }
}

class PaymentPlanOption {
  const PaymentPlanOption({
    required this.planType,
    required this.label,
    this.recommended = false,
    this.originalPrice = 0.0,
    this.discount = 0.0,
    this.finalPrice = 0.0,
    this.amountDueToday = 0.0,
    this.amountSaved = 0.0,
    this.installmentCount = 1,
    this.installmentAmount,
    this.durationMonths = 1,
    this.totalPayable = 0.0,
    this.remainingAfterToday = 0.0,
    this.benefits = const [],
  });

  final String planType; // 'full' or 'monthly'
  final String label;
  final bool recommended;
  final double originalPrice;
  final double discount;
  final double finalPrice;
  final double amountDueToday;
  final double amountSaved;
  final int installmentCount;
  final double? installmentAmount;
  final int durationMonths;
  final double totalPayable;
  final double remainingAfterToday;
  final List<String> benefits;

  bool get isFull => planType.toLowerCase() == 'full';
  bool get isMonthly => planType.toLowerCase() == 'monthly' || installmentCount > 1;

  factory PaymentPlanOption.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'] ?? [];
    final benefits = (rawBenefits is List) ? rawBenefits.map((b) => b.toString()).toList() : <String>[];

    return PaymentPlanOption(
      planType: json['plan_type']?.toString() ?? 'full',
      label: json['label']?.toString() ?? 'Pay in Full',
      recommended: json['recommended'] == true,
      originalPrice: double.tryParse(json['original']?.toString() ?? json['original_price']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      finalPrice: double.tryParse(json['final']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      amountDueToday: double.tryParse(json['amount_due_today']?.toString() ?? '0') ?? 0.0,
      amountSaved: double.tryParse(json['amount_saved']?.toString() ?? '0') ?? 0.0,
      installmentCount: int.tryParse(json['installment_count']?.toString() ?? '1') ?? 1,
      installmentAmount: double.tryParse(json['installment_amount']?.toString() ?? ''),
      durationMonths: int.tryParse(json['duration_months']?.toString() ?? '1') ?? 1,
      totalPayable: double.tryParse(json['total_payable']?.toString() ?? '0') ?? 0.0,
      remainingAfterToday: double.tryParse(json['remaining_after_today']?.toString() ?? '0') ?? 0.0,
      benefits: benefits,
    );
  }
}
