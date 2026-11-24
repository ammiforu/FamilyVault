class PropertyAsset {
  final String id;
  String title; // e.g. "Primary Home", "Vacation Lake House", "Farm Land"
  String propertyType; // Single Family, Condo, Land, Rental, Commercial
  String fullAddress;
  double? latitude;
  double? longitude;
  double purchasePrice;
  double estimatedMarketValue;
  double mortgageRemaining;
  String parcelNumber;
  DateTime? propertyTaxDueDate;
  String assignedMember;
  String notes;

  PropertyAsset({
    required this.id,
    required this.title,
    this.propertyType = 'Single Family Home',
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.purchasePrice = 0.0,
    this.estimatedMarketValue = 0.0,
    this.mortgageRemaining = 0.0,
    this.parcelNumber = '',
    this.propertyTaxDueDate,
    this.assignedMember = 'Entire Family',
    this.notes = '',
  });

  double get equity => (estimatedMarketValue - mortgageRemaining).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'propertyType': propertyType,
    'fullAddress': fullAddress,
    'latitude': latitude,
    'longitude': longitude,
    'purchasePrice': purchasePrice,
    'estimatedMarketValue': estimatedMarketValue,
    'mortgageRemaining': mortgageRemaining,
    'parcelNumber': parcelNumber,
    'propertyTaxDueDate': propertyTaxDueDate?.toIso8601String(),
    'assignedMember': assignedMember,
    'notes': notes,
  };

  factory PropertyAsset.fromJson(Map<String, dynamic> json) => PropertyAsset(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Property',
    propertyType: json['propertyType'] as String? ?? 'Single Family Home',
    fullAddress: json['fullAddress'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
    estimatedMarketValue: (json['estimatedMarketValue'] as num?)?.toDouble() ?? 0.0,
    mortgageRemaining: (json['mortgageRemaining'] as num?)?.toDouble() ?? 0.0,
    parcelNumber: json['parcelNumber'] as String? ?? '',
    propertyTaxDueDate: json['propertyTaxDueDate'] != null
        ? DateTime.tryParse(json['propertyTaxDueDate'] as String)
        : null,
    assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
    notes: json['notes'] as String? ?? '',
  );
}
