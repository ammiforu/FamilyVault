class MaintenanceLog {
  final String id;
  String serviceType; // Oil Change, Tire Rotation, Brakes, Inspection
  DateTime date;
  int mileage;
  double cost;
  String serviceCenter;
  String notes;

  MaintenanceLog({
    required this.id,
    required this.serviceType,
    required this.date,
    required this.mileage,
    required this.cost,
    this.serviceCenter = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'serviceType': serviceType,
    'date': date.toIso8601String(),
    'mileage': mileage,
    'cost': cost,
    'serviceCenter': serviceCenter,
    'notes': notes,
  };

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) => MaintenanceLog(
    id: json['id'] as String? ?? '',
    serviceType: json['serviceType'] as String? ?? 'Service',
    date: json['date'] != null ? DateTime.tryParse(json['date'] as String) ?? DateTime.now() : DateTime.now(),
    mileage: json['mileage'] as int? ?? 0,
    cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    serviceCenter: json['serviceCenter'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );
}

class Vehicle {
  final String id;
  String nickname; // "Family SUV", "Dad's Commuter"
  String make; // Toyota, Honda, Ford, Tesla
  String model; // Highlander, F-150, Civic
  int year;
  String licensePlate;
  String vin;
  int currentMileage;
  int oilChangeDueMileage;
  DateTime? registrationExpiry;
  String insuranceCompany;
  String insurancePolicyNumber;
  DateTime? insuranceExpiry;
  String assignedMember;
  double estimatedValue;
  List<MaintenanceLog> logs;

  Vehicle({
    required this.id,
    required this.nickname,
    required this.make,
    required this.model,
    required this.year,
    this.licensePlate = '',
    this.vin = '',
    this.currentMileage = 0,
    this.oilChangeDueMileage = 0,
    this.registrationExpiry,
    this.insuranceCompany = '',
    this.insurancePolicyNumber = '',
    this.insuranceExpiry,
    this.assignedMember = 'Entire Family',
    this.estimatedValue = 0.0,
    List<MaintenanceLog>? logs,
  }) : logs = logs ?? [];

  bool get isOilChangeDue => currentMileage > 0 && oilChangeDueMileage > 0 && currentMileage >= oilChangeDueMileage;

  int? get daysUntilRegistrationExpires {
    if (registrationExpiry == null) return null;
    return registrationExpiry!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'make': make,
    'model': model,
    'year': year,
    'licensePlate': licensePlate,
    'vin': vin,
    'currentMileage': currentMileage,
    'oilChangeDueMileage': oilChangeDueMileage,
    'registrationExpiry': registrationExpiry?.toIso8601String(),
    'insuranceCompany': insuranceCompany,
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceExpiry': insuranceExpiry?.toIso8601String(),
    'assignedMember': assignedMember,
    'estimatedValue': estimatedValue,
    'logs': logs.map((l) => l.toJson()).toList(),
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String? ?? '',
    nickname: json['nickname'] as String? ?? 'Vehicle',
    make: json['make'] as String? ?? '',
    model: json['model'] as String? ?? '',
    year: json['year'] as int? ?? DateTime.now().year,
    licensePlate: json['licensePlate'] as String? ?? '',
    vin: json['vin'] as String? ?? '',
    currentMileage: json['currentMileage'] as int? ?? 0,
    oilChangeDueMileage: json['oilChangeDueMileage'] as int? ?? 0,
    registrationExpiry: json['registrationExpiry'] != null
        ? DateTime.tryParse(json['registrationExpiry'] as String)
        : null,
    insuranceCompany: json['insuranceCompany'] as String? ?? '',
    insurancePolicyNumber: json['insurancePolicyNumber'] as String? ?? '',
    insuranceExpiry: json['insuranceExpiry'] != null
        ? DateTime.tryParse(json['insuranceExpiry'] as String)
        : null,
    assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
    estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0.0,
    logs: (json['logs'] as List<dynamic>?)
            ?.map((e) => MaintenanceLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
