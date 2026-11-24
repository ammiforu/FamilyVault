class WarrantyReceipt {
  final String id;
  String itemName; // e.g. "Samsung 65-inch OLED 4K TV"
  String category; // Electronics, Appliances, Tools, Furniture, Jewelry, Auto
  String storeMerchant; // Best Buy, Amazon, Apple, Home Depot, Costco
  DateTime purchaseDate;
  double price;
  int warrantyPeriodMonths; // e.g. 12, 24, 36, 60
  String serialNumber;
  String receiptNumber;
  String assignedMember;
  String notes;
  String returnPolicyDays;
  String imagePath;

  WarrantyReceipt({
    required this.id,
    required this.itemName,
    this.category = 'Electronics',
    required this.storeMerchant,
    required this.purchaseDate,
    required this.price,
    this.warrantyPeriodMonths = 12,
    this.serialNumber = '',
    this.receiptNumber = '',
    this.assignedMember = 'Entire Family',
    this.notes = '',
    this.returnPolicyDays = '30',
    this.imagePath = '',
  });

  DateTime get warrantyExpiryDate {
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyPeriodMonths,
      purchaseDate.day,
    );
  }

  int get daysUntilWarrantyExpires {
    return warrantyExpiryDate.difference(DateTime.now()).inDays;
  }

  bool get isExpired => daysUntilWarrantyExpires < 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemName': itemName,
    'category': category,
    'storeMerchant': storeMerchant,
    'purchaseDate': purchaseDate.toIso8601String(),
    'price': price,
    'warrantyPeriodMonths': warrantyPeriodMonths,
    'serialNumber': serialNumber,
    'receiptNumber': receiptNumber,
    'assignedMember': assignedMember,
    'notes': notes,
    'returnPolicyDays': returnPolicyDays,
    'imagePath': imagePath,
  };

  factory WarrantyReceipt.fromJson(Map<String, dynamic> json) => WarrantyReceipt(
    id: json['id'] as String? ?? '',
    itemName: json['itemName'] as String? ?? 'Item',
    category: json['category'] as String? ?? 'Electronics',
    storeMerchant: json['storeMerchant'] as String? ?? 'Store',
    purchaseDate: json['purchaseDate'] != null
        ? DateTime.tryParse(json['purchaseDate'] as String) ?? DateTime.now()
        : DateTime.now(),
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    warrantyPeriodMonths: json['warrantyPeriodMonths'] as int? ?? 12,
    serialNumber: json['serialNumber'] as String? ?? '',
    receiptNumber: json['receiptNumber'] as String? ?? '',
    assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
    notes: json['notes'] as String? ?? '',
    returnPolicyDays: json['returnPolicyDays'] as String? ?? '30',
    imagePath: json['imagePath'] as String? ?? '',
  );
}
