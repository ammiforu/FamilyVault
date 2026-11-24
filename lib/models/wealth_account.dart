enum AccountType {
  checking,
  savings,
  investment,
  retirement, // 401k, IRA
  crypto,
  creditCard,
  mortgage,
  loan, // Auto loan, Student loan
  cash;

  String get displayName {
    switch (this) {
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'High-Yield Savings';
      case AccountType.investment:
        return 'Brokerage / Stocks';
      case AccountType.retirement:
        return '401(k) / Roth IRA';
      case AccountType.crypto:
        return 'Crypto Wallet';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.mortgage:
        return 'Mortgage';
      case AccountType.loan:
        return 'Personal / Auto Loan';
      case AccountType.cash:
        return 'Physical Cash / Safe';
    }
  }

  bool get isLiability {
    return this == AccountType.creditCard ||
        this == AccountType.mortgage ||
        this == AccountType.loan;
  }
}

class WealthAccount {
  final String id;
  String institution; // e.g., Chase, Vanguard, Fidelity, Wells Fargo
  AccountType accountType;
  String accountName; // e.g. "Emergency Fund", "Joint Checking"
  String maskedNumber; // e.g., "...9421"
  double balance;
  String currency;
  String assignedMember; // e.g. "Dad & Mom", "Emma College Fund"
  DateTime lastUpdated;
  String notes;

  WealthAccount({
    required this.id,
    required this.institution,
    required this.accountType,
    required this.accountName,
    this.maskedNumber = '',
    required this.balance,
    this.currency = 'USD',
    this.assignedMember = 'Entire Family',
    DateTime? lastUpdated,
    this.notes = '',
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  bool get isLiability => accountType.isLiability;

  Map<String, dynamic> toJson() => {
    'id': id,
    'institution': institution,
    'accountType': accountType.name,
    'accountName': accountName,
    'maskedNumber': maskedNumber,
    'balance': balance,
    'currency': currency,
    'assignedMember': assignedMember,
    'lastUpdated': lastUpdated.toIso8601String(),
    'notes': notes,
  };

  factory WealthAccount.fromJson(Map<String, dynamic> json) => WealthAccount(
    id: json['id'] as String? ?? '',
    institution: json['institution'] as String? ?? 'Bank',
    accountType: AccountType.values.firstWhere(
      (e) => e.name == json['accountType'],
      orElse: () => AccountType.checking,
    ),
    accountName: json['accountName'] as String? ?? '',
    maskedNumber: json['maskedNumber'] as String? ?? '',
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'USD',
    assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
        : DateTime.now(),
    notes: json['notes'] as String? ?? '',
  );
}
