class FamilyMember {
  final String id;
  String name;
  String role; // 'Head of Family', 'Parent', 'Spouse', 'Child', 'Dependent'
  int colorValue;
  bool isCurrentUser;
  String email;
  String phone;

  FamilyMember({
    required this.id,
    required this.name,
    this.role = 'Parent',
    this.colorValue = 0xFF1E88E5,
    this.isCurrentUser = false,
    this.email = '',
    this.phone = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'colorValue': colorValue,
    'isCurrentUser': isCurrentUser,
    'email': email,
    'phone': phone,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Member',
    role: json['role'] as String? ?? 'Parent',
    colorValue: json['colorValue'] as int? ?? 0xFF1E88E5,
    isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}
