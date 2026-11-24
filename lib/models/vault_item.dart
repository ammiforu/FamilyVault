enum VaultCategory {
  login,
  card,
  document,
  legal,
  emergency,
  wifi,
  note;

  String get displayName {
    switch (this) {
      case VaultCategory.login:
        return 'Accounts & Logins';
      case VaultCategory.card:
        return 'Banking & Cards';
      case VaultCategory.document:
        return 'Passports, Visas & IDs';
      case VaultCategory.legal:
        return 'Wills & Legal Documents';
      case VaultCategory.emergency:
        return 'Emergency (ICE)';
      case VaultCategory.wifi:
        return 'Wi-Fi & Home Codes';
      case VaultCategory.note:
        return 'Secure Notes';
    }
  }

  String get shortCode {
    switch (this) {
      case VaultCategory.login:
        return 'LOGIN';
      case VaultCategory.card:
        return 'CARD';
      case VaultCategory.document:
        return 'DOC/ID';
      case VaultCategory.legal:
        return 'LEGAL';
      case VaultCategory.emergency:
        return 'ICE';
      case VaultCategory.wifi:
        return 'WIFI';
      case VaultCategory.note:
        return 'NOTE';
    }
  }

  static VaultCategory fromString(String val) {
    for (final cat in VaultCategory.values) {
      if (cat.name.toLowerCase() == val.toLowerCase() ||
          cat.displayName.toLowerCase() == val.toLowerCase() ||
          cat.shortCode.toLowerCase() == val.toLowerCase()) {
        return cat;
      }
    }
    return VaultCategory.login;
  }
}

class VaultItem {
  final String id;
  String title;
  VaultCategory category;
  String username;
  String password;
  String url;
  String assignedMember;
  String notes;
  String expiryDate;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;

  VaultItem({
    required this.id,
    required this.title,
    required this.category,
    this.username = '',
    this.password = '',
    this.url = '',
    this.assignedMember = 'Entire Family',
    this.notes = '',
    this.expiryDate = '',
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'username': username,
      'password': password,
      'url': url,
      'assignedMember': assignedMember,
      'notes': notes,
      'expiryDate': expiryDate,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      category: VaultCategory.fromString(json['category'] as String? ?? 'login'),
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      url: json['url'] as String? ?? '',
      assignedMember: json['assignedMember'] as String? ?? 'Entire Family',
      notes: json['notes'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  List<dynamic> toCsvRow() {
    return [
      title,
      category.displayName,
      assignedMember,
      username,
      password,
      url,
      expiryDate,
      notes,
      updatedAt.toIso8601String(),
    ];
  }

  static List<String> csvHeaders() {
    return [
      'Title / Service',
      'Category',
      'Assigned Member',
      'Username / Email',
      'Password / Secret',
      'URL / Location',
      'Expiry / Renewal Date',
      'Notes',
      'Last Updated',
    ];
  }

  static VaultItem fromCsvRow(List<dynamic> row, String newId) {
    return VaultItem(
      id: newId,
      title: row.isNotEmpty ? row[0].toString() : 'Imported Item',
      category: row.length > 1 ? VaultCategory.fromString(row[1].toString()) : VaultCategory.login,
      assignedMember: row.length > 2 && row[2].toString().isNotEmpty ? row[2].toString() : 'Entire Family',
      username: row.length > 3 ? row[3].toString() : '',
      password: row.length > 4 ? row[4].toString() : '',
      url: row.length > 5 ? row[5].toString() : '',
      expiryDate: row.length > 6 ? row[6].toString() : '',
      notes: row.length > 7 ? row[7].toString() : '',
    );
  }

  VaultItem copyWith({
    String? id,
    String? title,
    VaultCategory? category,
    String? username,
    String? password,
    String? url,
    String? assignedMember,
    String? notes,
    String? expiryDate,
    bool? isFavorite,
  }) {
    return VaultItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      assignedMember: assignedMember ?? this.assignedMember,
      notes: notes ?? this.notes,
      expiryDate: expiryDate ?? this.expiryDate,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
