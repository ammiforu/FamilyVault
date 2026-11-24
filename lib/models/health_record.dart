class HealthRecord {
  final String id;
  String memberName;
  String bloodGroup; // A+, O+, B+, etc.
  String allergies;
  String medications;
  String conditions;
  String primaryDoctor;
  String doctorPhone;
  String immunizations; // e.g. Tetanus 2024, Flu 2026
  String notes;

  HealthRecord({
    required this.id,
    required this.memberName,
    this.bloodGroup = '',
    this.allergies = 'None',
    this.medications = 'None',
    this.conditions = '',
    this.primaryDoctor = '',
    this.doctorPhone = '',
    this.immunizations = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberName': memberName,
    'bloodGroup': bloodGroup,
    'allergies': allergies,
    'medications': medications,
    'conditions': conditions,
    'primaryDoctor': primaryDoctor,
    'doctorPhone': doctorPhone,
    'immunizations': immunizations,
    'notes': notes,
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
    id: json['id'] as String? ?? '',
    memberName: json['memberName'] as String? ?? 'Member',
    bloodGroup: json['bloodGroup'] as String? ?? '',
    allergies: json['allergies'] as String? ?? 'None',
    medications: json['medications'] as String? ?? 'None',
    conditions: json['conditions'] as String? ?? '',
    primaryDoctor: json['primaryDoctor'] as String? ?? '',
    doctorPhone: json['doctorPhone'] as String? ?? '',
    immunizations: json['immunizations'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );
}
