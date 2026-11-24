enum InsuranceType {
  lifeLic,
  health,
  auto,
  home,
  other;

  String get displayName {
    switch (this) {
      case InsuranceType.lifeLic:
        return 'Life Insurance / LIC';
      case InsuranceType.health:
        return 'Health / Medical';
      case InsuranceType.auto:
        return 'Auto / Vehicle';
      case InsuranceType.home:
        return 'Home / Property';
      case InsuranceType.other:
        return 'Other Policy';
    }
  }
}

class InsurancePolicy {
  final String id;
  InsuranceType type;
  String provider; // e.g. LIC of India, MetLife, Prudential, BlueCross
  String policyName; // e.g. LIC Jeevan Anand, Family Term Plan
  String policyNumber;
  String insuredMember;
  String nomineeName; // Crucial for Life / LIC
  double coverageAmount; // Sum Assured
  double premiumAmount;
  String premiumFrequency; // Monthly, Quarterly, Half-Yearly, Annual
  DateTime? nextPremiumDueDate;
  DateTime? maturityOrExpiryDate;
  String agentName;
  String agentPhone;
  String agentEmail;
  String agentCode;
  String claimStatus; // None, Claim Filed, Under Review, Settled
  String claimReferenceNumber;
  String policyDocPath; // Photo/scan of Policy / LIC Bond
  String claimDocPath; // Photo/scan of Claim / Hospital / Supporting Doc
  String notes;

  InsurancePolicy({
    required this.id,
    this.type = InsuranceType.lifeLic,
    required this.provider,
    required this.policyName,
    this.policyNumber = '',
    this.insuredMember = 'Entire Family',
    this.nomineeName = '',
    this.coverageAmount = 0.0,
    this.premiumAmount = 0.0,
    this.premiumFrequency = 'Annual',
    this.nextPremiumDueDate,
    this.maturityOrExpiryDate,
    this.agentName = '',
    this.agentPhone = '',
    this.agentEmail = '',
    this.agentCode = '',
    this.claimStatus = 'Active Policy',
    this.claimReferenceNumber = '',
    this.policyDocPath = '',
    this.claimDocPath = '',
    this.notes = '',
  });

  int? get daysUntilNextPremium {
    if (nextPremiumDueDate == null) return null;
    return nextPremiumDueDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'provider': provider,
    'policyName': policyName,
    'policyNumber': policyNumber,
    'insuredMember': insuredMember,
    'nomineeName': nomineeName,
    'coverageAmount': coverageAmount,
    'premiumAmount': premiumAmount,
    'premiumFrequency': premiumFrequency,
    'nextPremiumDueDate': nextPremiumDueDate?.toIso8601String(),
    'maturityOrExpiryDate': maturityOrExpiryDate?.toIso8601String(),
    'agentName': agentName,
    'agentPhone': agentPhone,
    'agentEmail': agentEmail,
    'agentCode': agentCode,
    'claimStatus': claimStatus,
    'claimReferenceNumber': claimReferenceNumber,
    'policyDocPath': policyDocPath,
    'claimDocPath': claimDocPath,
    'notes': notes,
  };

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) => InsurancePolicy(
    id: json['id'] as String? ?? '',
    type: InsuranceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => InsuranceType.lifeLic,
    ),
    provider: json['provider'] as String? ?? 'Insurance',
    policyName: json['policyName'] as String? ?? 'Policy',
    policyNumber: json['policyNumber'] as String? ?? '',
    insuredMember: json['insuredMember'] as String? ?? 'Entire Family',
    nomineeName: json['nomineeName'] as String? ?? '',
    coverageAmount: (json['coverageAmount'] as num?)?.toDouble() ?? 0.0,
    premiumAmount: (json['premiumAmount'] as num?)?.toDouble() ?? 0.0,
    premiumFrequency: json['premiumFrequency'] as String? ?? 'Annual',
    nextPremiumDueDate: json['nextPremiumDueDate'] != null
        ? DateTime.tryParse(json['nextPremiumDueDate'] as String)
        : null,
    maturityOrExpiryDate: json['maturityOrExpiryDate'] != null
        ? DateTime.tryParse(json['maturityOrExpiryDate'] as String)
        : null,
    agentName: json['agentName'] as String? ?? '',
    agentPhone: json['agentPhone'] as String? ?? '',
    agentEmail: json['agentEmail'] as String? ?? '',
    agentCode: json['agentCode'] as String? ?? '',
    claimStatus: json['claimStatus'] as String? ?? 'Active Policy',
    claimReferenceNumber: json['claimReferenceNumber'] as String? ?? '',
    policyDocPath: json['policyDocPath'] as String? ?? '',
    claimDocPath: json['claimDocPath'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );
}
