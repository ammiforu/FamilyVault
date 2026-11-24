class RecurringBill {
  final String id;
  String name; // e.g. Mortgage, Electricity, Internet, Netflix
  String category; // Housing, Utilities, Subscriptions, Insurance, Education
  double amount;
  String frequency; // Monthly, Quarterly, Annual
  int dueDayOfMonth; // 1..31
  bool isAutoPay;
  String assignedMember;
  String notes;

  RecurringBill({
    required this.id,
    required this.name,
    this.category = 'Utilities',
    required this.amount,
    this.frequency = 'Monthly',
    this.dueDayOfMonth = 1,
    this.isAutoPay = true,
    this.assignedMember = 'Entire Family',
    this.notes = '',
  });

  double get monthlyEquivalent {
    if (frequency == 'Annual') return amount / 12.0;
    if (frequency == 'Quarterly') return amount / 3.0;
    return amount;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'amount': amount,
    'frequency': frequency,
    'dueDayOfMonth': dueDayOfMonth,
    'isAutoPay': isAutoPay,
    'assignedMember': assignedMember,
    'notes': notes,
  };

  factory RecurringBill.fromJson(Map<String, dynamic> json) => RecurringBill(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Bill',
    category: json['category'] as String? ?? 'Utilities',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    frequency: json['frequency'] as String? ?? 'Monthly',
    dueDayOfMonth: json['dueDayOfMonth'] as int? ?? 1,
    isAutoPay: json['isAutoPay'] as bool? ?? true,
    assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
    notes: json['notes'] as String? ?? '',
  );
}
