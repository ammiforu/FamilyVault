import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';
import '../models/property_asset.dart';
import '../models/vault_item.dart';
import '../models/vehicle.dart';
import '../models/warranty_receipt.dart';
import '../models/wealth_account.dart';
import 'encryption_service.dart';

class StorageService {
  static const String _keyPinHash = 'master_pin_hash';
  static const String _keyHasSetup = 'vault_is_setup';
  static const String _keyWebBundle = 'family_vault_web_bundle_v2';
  static const String _vaultFileName = 'family_vault_bundle_v2.enc';

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  List<VaultItem> _items = [];
  List<WealthAccount> _wealthAccounts = [];
  List<Vehicle> _vehicles = [];
  List<PropertyAsset> _properties = [];
  List<WarrantyReceipt> _warranties = [];
  List<FamilyMember> _members = [];
  String _activeMemberId = '';
  bool _isSampleData = true;
  Map<String, double> _exchangeRates = {'USD': 1.0};

  String _currentSessionPin = '';

  List<VaultItem> get items => List.unmodifiable(_items);
  List<WealthAccount> get wealthAccounts => List.unmodifiable(_wealthAccounts);
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<PropertyAsset> get properties => List.unmodifiable(_properties);
  List<WarrantyReceipt> get warranties => List.unmodifiable(_warranties);
  List<FamilyMember> get members => List.unmodifiable(_members);
  String get activeMemberId => _activeMemberId;
  bool get isSampleData => _isSampleData;
  Map<String, double> get exchangeRates => _exchangeRates;

  void updateExchangeRates(Map<String, double> rates) {
    if (rates.isNotEmpty) {
      _exchangeRates = rates;
    }
  }

  double _toUsd(double amount, String currency) {
    if (currency == 'USD') return amount;
    final rate = _exchangeRates[currency];
    if (rate == null || rate == 0) return amount;
    return amount / rate;
  }

  Future<void> clearAllDataAndStartFresh() async {
    _items = [];
    _wealthAccounts = [];
    _vehicles = [];
    _properties = [];
    _warranties = [];
    _members = [
      FamilyMember(
        id: 'member_primary',
        name: 'My Family',
        role: 'Admin',
        colorValue: 0xFF10B981,
        isCurrentUser: true,
      ),
    ];
    _activeMemberId = 'member_primary';
    _isSampleData = false;
    await saveVaultBundle();
  }

  Future<void> loadSampleData() async {
    _isSampleData = true;
    await _seedDefaultDemoData();
  }

  List<({String title, String subtitle, bool isUrgent, int tabIndex})> getUpcomingAlerts() {
    final alerts = <({String title, String subtitle, bool isUrgent, int tabIndex})>[];

    for (final v in _vehicles) {
      if (v.isOilChangeDue) {
        alerts.add((
          title: '${v.nickname}: Oil Change Due',
          subtitle: 'Current ${v.currentMileage} mi (due at ${v.oilChangeDueMileage} mi)',
          isUrgent: true,
          tabIndex: 3,
        ));
      }
      final regDays = v.daysUntilRegistrationExpires;
      if (regDays != null && regDays <= 45) {
        alerts.add((
          title: '${v.nickname}: Registration',
          subtitle: regDays < 0 ? 'Expired ${regDays.abs()} days ago' : 'Expires in $regDays days',
          isUrgent: regDays <= 14,
          tabIndex: 3,
        ));
      }
    }

    for (final w in _warranties) {
      final days = w.daysUntilWarrantyExpires;
      if (days >= 0 && days <= 45) {
        alerts.add((
          title: '${w.itemName}: Warranty',
          subtitle: 'Expires in $days days (${w.storeMerchant})',
          isUrgent: days <= 14,
          tabIndex: 5,
        ));
      }
    }

    for (final p in _properties) {
      if (p.propertyTaxDueDate != null) {
        final days = p.propertyTaxDueDate!.difference(DateTime.now()).inDays;
        if (days <= 60) {
          alerts.add((
            title: '${p.title}: Property Tax',
            subtitle: days < 0 ? 'Past due by ${days.abs()} days' : 'Due in $days days',
            isUrgent: days <= 15,
            tabIndex: 4,
          ));
        }
      }
    }

    return alerts;
  }

  FamilyMember? get activeMember {
    try {
      return _members.firstWhere((m) => m.id == _activeMemberId);
    } catch (_) {
      return _members.isNotEmpty ? _members.first : null;
    }
  }

  void setActiveMember(String id) {
    _activeMemberId = id;
    for (final m in _members) {
      m.isCurrentUser = (m.id == id);
    }
    saveVaultBundle();
  }

  void setSessionPin(String pin) {
    _currentSessionPin = pin;
  }

  void clearSession() {
    _currentSessionPin = '';
  }

  Future<bool> isVaultConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSetup) ?? false;
  }

  Future<void> setupMasterPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = EncryptionService.hashPin(newPin);
    await prefs.setString(_keyPinHash, hash);
    await prefs.setBool(_keyHasSetup, true);
    _currentSessionPin = newPin;

    if (_items.isEmpty && _wealthAccounts.isEmpty) {
      await _seedDefaultDemoData();
    }
  }

  Future<bool> verifyMasterPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_keyPinHash) ?? '';
    if (hash.isEmpty) return false;

    final isValid = EncryptionService.verifyPin(enteredPin, hash);
    if (isValid) {
      _currentSessionPin = enteredPin;
    }
    return isValid;
  }

  // NET WORTH CALCULATIONS
  double get totalAssets {
    double sum = 0.0;
    for (final a in _wealthAccounts) {
      if (!a.isLiability) sum += _toUsd(a.balance, a.currency);
    }
    for (final v in _vehicles) {
      sum += v.estimatedValue;
    }
    for (final p in _properties) {
      sum += p.estimatedMarketValue;
    }
    return sum;
  }

  double get totalLiabilities {
    double sum = 0.0;
    for (final a in _wealthAccounts) {
      if (a.isLiability) sum += _toUsd(a.balance, a.currency);
    }
    for (final p in _properties) {
      sum += p.mortgageRemaining;
    }
    return sum;
  }

  double get netWorth => totalAssets - totalLiabilities;

  Future<File> _getLocalBundleFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_vaultFileName');
  }

  Future<void> loadVaultBundle() async {
    try {
      String encryptedContent = '';
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        encryptedContent = prefs.getString(_keyWebBundle) ?? '';
      } else {
        final file = await _getLocalBundleFile();
        if (!await file.exists()) {
          await _seedDefaultDemoData();
          return;
        }
        encryptedContent = await file.readAsString();
      }

      if (encryptedContent.trim().isEmpty) {
        await _seedDefaultDemoData();
        return;
      }

      final plainJson = EncryptionService.decryptPayload(encryptedContent, _currentSessionPin);
      if (plainJson.isEmpty) {
        await _seedDefaultDemoData();
        return;
      }

      final Map<String, dynamic> data = json.decode(plainJson) as Map<String, dynamic>;

      _items = (data['items'] as List<dynamic>?)
              ?.map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _wealthAccounts = (data['wealthAccounts'] as List<dynamic>?)
              ?.map((e) => WealthAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _vehicles = (data['vehicles'] as List<dynamic>?)
              ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _properties = (data['properties'] as List<dynamic>?)
              ?.map((e) => PropertyAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _warranties = (data['warranties'] as List<dynamic>?)
              ?.map((e) => WarrantyReceipt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _members = (data['members'] as List<dynamic>?)
              ?.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _activeMemberId = data['activeMemberId'] as String? ?? (_members.isNotEmpty ? _members.first.id : '');
      _isSampleData = data['isSampleData'] as bool? ?? false;

      if (_members.isEmpty) {
        await _seedDefaultDemoData();
      }
    } catch (_) {
      if (_members.isEmpty) {
        await _seedDefaultDemoData();
      }
    }
  }

  Future<void> saveVaultBundle() async {
    try {
      final bundleMap = {
        'version': 2,
        'updatedAt': DateTime.now().toIso8601String(),
        'activeMemberId': _activeMemberId,
        'isSampleData': _isSampleData,
        'items': _items.map((e) => e.toJson()).toList(),
        'wealthAccounts': _wealthAccounts.map((e) => e.toJson()).toList(),
        'vehicles': _vehicles.map((e) => e.toJson()).toList(),
        'properties': _properties.map((e) => e.toJson()).toList(),
        'warranties': _warranties.map((e) => e.toJson()).toList(),
        'members': _members.map((e) => e.toJson()).toList(),
      };

      final jsonString = json.encode(bundleMap);
      final encryptedContent = EncryptionService.encryptPayload(jsonString, _currentSessionPin);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyWebBundle, encryptedContent);
      } else {
        final file = await _getLocalBundleFile();
        await file.writeAsString(encryptedContent, flush: true);
      }
    } catch (_) {}
  }

  // CRUD FOR ALL CATEGORIES
  Future<void> addItem(VaultItem item) => addVaultItem(item);
  Future<void> updateItem(VaultItem item) => updateVaultItem(item);
  Future<void> deleteItem(String id) => deleteVaultItem(id);
  String exportToCsv() => exportAllToCsv();
  Future<int> importFromCsv(String content) => importSmartCsv(content);

  Future<void> toggleFavorite(String id) async {
    final idx = _items.indexWhere((it) => it.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isFavorite: !_items[idx].isFavorite);
      await saveVaultBundle();
    }
  }

  Future<void> addVaultItem(VaultItem item) async {
    _items.insert(0, item);
    await saveVaultBundle();
  }

  Future<void> updateVaultItem(VaultItem item) async {
    final idx = _items.indexWhere((it) => it.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
      await saveVaultBundle();
    }
  }

  Future<void> deleteVaultItem(String id) async {
    _items.removeWhere((it) => it.id == id);
    await saveVaultBundle();
  }

  Future<void> addWealthAccount(WealthAccount account) async {
    _wealthAccounts.insert(0, account);
    await saveVaultBundle();
  }

  Future<void> updateWealthAccount(WealthAccount account) async {
    final idx = _wealthAccounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _wealthAccounts[idx] = account;
      await saveVaultBundle();
    }
  }

  Future<void> deleteWealthAccount(String id) async {
    _wealthAccounts.removeWhere((a) => a.id == id);
    await saveVaultBundle();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.insert(0, vehicle);
    await saveVaultBundle();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) {
      _vehicles[idx] = vehicle;
      await saveVaultBundle();
    }
  }

  Future<void> deleteVehicle(String id) async {
    _vehicles.removeWhere((v) => v.id == id);
    await saveVaultBundle();
  }

  Future<void> addProperty(PropertyAsset property) async {
    _properties.insert(0, property);
    await saveVaultBundle();
  }

  Future<void> updateProperty(PropertyAsset property) async {
    final idx = _properties.indexWhere((p) => p.id == property.id);
    if (idx != -1) {
      _properties[idx] = property;
      await saveVaultBundle();
    }
  }

  Future<void> deleteProperty(String id) async {
    _properties.removeWhere((p) => p.id == id);
    await saveVaultBundle();
  }

  Future<void> addWarranty(WarrantyReceipt warranty) async {
    _warranties.insert(0, warranty);
    await saveVaultBundle();
  }

  Future<void> updateWarranty(WarrantyReceipt warranty) async {
    final idx = _warranties.indexWhere((w) => w.id == warranty.id);
    if (idx != -1) {
      _warranties[idx] = warranty;
      await saveVaultBundle();
    }
  }

  Future<void> deleteWarranty(String id) async {
    _warranties.removeWhere((w) => w.id == id);
    await saveVaultBundle();
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    _members.add(member);
    await saveVaultBundle();
  }

  Future<void> deleteFamilyMember(String id) async {
    if (_members.length <= 1) return;
    _members.removeWhere((m) => m.id == id);
    if (_activeMemberId == id) {
      _activeMemberId = _members.first.id;
    }
    await saveVaultBundle();
  }

  // SMART GOOGLE SHEETS PARSER & CSV EXPORT
  String exportAllToCsv() {
    final List<List<dynamic>> rows = [
      ['SECTION', 'NAME / TITLE', 'CATEGORY / TYPE', 'MEMBER', 'VALUE / SECRET', 'EXTRA / ADDRESS', 'EXPIRY / DUE', 'NOTES'],
      ..._wealthAccounts.map((a) => ['WEALTH', a.institution, a.accountType.displayName, a.assignedMember, '\$${a.balance.toStringAsFixed(2)}', a.maskedNumber, '-', a.notes]),
      ..._vehicles.map((v) => ['VEHICLE', '${v.year} ${v.make} ${v.model}', 'Vehicle', v.assignedMember, '\$${v.estimatedValue.toStringAsFixed(0)}', 'Plate: ${v.licensePlate} | Mileage: ${v.currentMileage}', v.registrationExpiry?.toIso8601String().substring(0, 10) ?? '-', 'Oil due at: ${v.oilChangeDueMileage} mi']),
      ..._properties.map((p) => ['PROPERTY', p.title, p.propertyType, p.assignedMember, '\$${p.estimatedMarketValue.toStringAsFixed(0)}', p.fullAddress, p.propertyTaxDueDate?.toIso8601String().substring(0, 10) ?? '-', 'Mortgage: \$${p.mortgageRemaining.toStringAsFixed(0)}']),
      ..._warranties.map((w) => ['WARRANTY', w.itemName, w.category, w.assignedMember, '\$${w.price.toStringAsFixed(2)}', 'Store: ${w.storeMerchant} | S/N: ${w.serialNumber}', w.warrantyExpiryDate.toIso8601String().substring(0, 10), w.notes]),
      ..._items.map((i) => ['VAULT', i.title, i.category.displayName, i.assignedMember, i.password, '${i.username} | ${i.url}', i.expiryDate, i.notes]),
    ];

    return rows.map((row) => row.map((cell) {
      final str = cell?.toString() ?? '';
      if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
        return '"${str.replaceAll('"', '""')}"';
      }
      return str;
    }).join(',')).join('\n');
  }

  Future<int> importSmartCsv(String csvContent) async {
    try {
      final lines = csvContent.split(RegExp(r'\r?\n'));
      if (lines.length <= 1) return 0;

      int count = 0;
      const uuid = Uuid();

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final row = _parseCsvLine(line);
        if (row.isEmpty || row[0].isEmpty) continue;

        final firstCol = row[0].toUpperCase();
        final title = row.length > 1 ? row[1] : row[0];
        final type = row.length > 2 ? row[2] : '';
        final member = row.length > 3 && row[3].isNotEmpty ? row[3] : 'Entire Family';
        final val = row.length > 4 ? row[4] : '';
        final extra = row.length > 5 ? row[5] : '';
        final expiry = row.length > 6 ? row[6] : '';
        final notes = row.length > 7 ? row[7] : '';

        if (firstCol.contains('WEALTH') || type.toLowerCase().contains('bank') || type.toLowerCase().contains('savings')) {
          final balance = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          _wealthAccounts.add(WealthAccount(
            id: uuid.v4(),
            institution: title,
            accountType: type.toLowerCase().contains('credit') ? AccountType.creditCard : AccountType.checking,
            accountName: type,
            balance: balance,
            assignedMember: member,
            notes: notes,
          ));
          count++;
        } else if (firstCol.contains('VEHICLE') || type.toLowerCase().contains('car') || type.toLowerCase().contains('vehicle')) {
          final price = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 15000.0;
          _vehicles.add(Vehicle(
            id: uuid.v4(),
            nickname: title,
            make: title.split(' ').first,
            model: title,
            year: DateTime.now().year,
            assignedMember: member,
            estimatedValue: price,
            registrationExpiry: DateTime.tryParse(expiry),
          ));
          count++;
        } else if (firstCol.contains('PROPERTY') || type.toLowerCase().contains('home') || type.toLowerCase().contains('land')) {
          final price = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 300000.0;
          _properties.add(PropertyAsset(
            id: uuid.v4(),
            title: title,
            propertyType: type.isNotEmpty ? type : 'Real Estate',
            fullAddress: extra,
            estimatedMarketValue: price,
            assignedMember: member,
            notes: notes,
          ));
          count++;
        } else if (firstCol.contains('WARRANTY') || type.toLowerCase().contains('receipt') || type.toLowerCase().contains('electronics')) {
          final price = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 199.0;
          _warranties.add(WarrantyReceipt(
            id: uuid.v4(),
            itemName: title,
            category: type.isNotEmpty ? type : 'Home',
            storeMerchant: extra.isNotEmpty ? extra : 'Retail',
            purchaseDate: DateTime.now(),
            price: price,
            assignedMember: member,
            notes: notes,
          ));
          count++;
        } else {
          // Standard Vault Item
          _items.add(VaultItem(
            id: uuid.v4(),
            title: title,
            category: VaultCategory.fromString(type),
            assignedMember: member,
            password: val,
            username: extra,
            expiryDate: expiry,
            notes: notes,
          ));
          count++;
        }
      }

      await saveVaultBundle();
      return count;
    } catch (_) {
      return 0;
    }
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    fields.add(sb.toString().trim());
    return fields;
  }

  // CLOUD BACKUP ENCRYPTED BUNDLE (JSON EXPORT/IMPORT)
  String exportCloudBackupJson() {
    final bundleMap = {
      'app': 'FamilyVault',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'members': _members.map((e) => e.toJson()).toList(),
      'wealthAccounts': _wealthAccounts.map((e) => e.toJson()).toList(),
      'vehicles': _vehicles.map((e) => e.toJson()).toList(),
      'properties': _properties.map((e) => e.toJson()).toList(),
      'warranties': _warranties.map((e) => e.toJson()).toList(),
      'items': _items.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(bundleMap);
  }

  Future<bool> restoreCloudBackupJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      if (!data.containsKey('app') && !data.containsKey('items')) return false;

      if (data.containsKey('items')) {
        _items = (data['items'] as List<dynamic>)
            .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data.containsKey('wealthAccounts')) {
        _wealthAccounts = (data['wealthAccounts'] as List<dynamic>)
            .map((e) => WealthAccount.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data.containsKey('vehicles')) {
        _vehicles = (data['vehicles'] as List<dynamic>)
            .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data.containsKey('properties')) {
        _properties = (data['properties'] as List<dynamic>)
            .map((e) => PropertyAsset.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data.containsKey('warranties')) {
        _warranties = (data['warranties'] as List<dynamic>)
            .map((e) => WarrantyReceipt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data.containsKey('members')) {
        _members = (data['members'] as List<dynamic>)
            .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      await saveVaultBundle();
      return true;
    } catch (_) {
      return false;
    }
  }

  // SEED COMPREHENSIVE REALISTIC FAMILY DATA
  Future<void> _seedDefaultDemoData() async {
    const uuid = Uuid();

    // 1. Members
    _members = [
      FamilyMember(id: 'member_dad', name: 'Robert (Dad)', role: 'Head of Family', colorValue: 0xFF1976D2, isCurrentUser: true, email: 'robert@family.org', phone: '+1 (555) 234-5678'),
      FamilyMember(id: 'member_mom', name: 'Sarah (Mom)', role: 'Parent', colorValue: 0xFFE91E63, email: 'sarah@family.org', phone: '+1 (555) 234-5679'),
      FamilyMember(id: 'member_emma', name: 'Emma (Daughter)', role: 'Child', colorValue: 0xFF9C27B0, phone: '+1 (555) 234-9011'),
      FamilyMember(id: 'member_liam', name: 'Liam (Son)', role: 'Child', colorValue: 0xFF4CAF50),
    ];
    _activeMemberId = 'member_dad';

    // 2. Wealth & Bank Accounts
    _wealthAccounts = [
      WealthAccount(
        id: uuid.v4(),
        institution: 'Chase Bank',
        accountType: AccountType.checking,
        accountName: 'Joint Household Checking',
        maskedNumber: '•••• 4921',
        balance: 14250.75,
        assignedMember: 'Dad & Mom',
        notes: 'Main bill payments, mortgage auto-pay, direct deposits.',
      ),
      WealthAccount(
        id: uuid.v4(),
        institution: 'Marcus by Goldman Sachs',
        accountType: AccountType.savings,
        accountName: 'High-Yield Emergency Fund (4.4% APY)',
        maskedNumber: '•••• 8812',
        balance: 38500.00,
        assignedMember: 'Entire Family',
        notes: '6 months of emergency living expenses.',
      ),
      WealthAccount(
        id: uuid.v4(),
        institution: 'Fidelity Investments',
        accountType: AccountType.retirement,
        accountName: 'Dad 401(k) + S&P 500 Index',
        maskedNumber: '•••• 1044',
        balance: 184200.00,
        assignedMember: 'Robert (Dad)',
        notes: 'Target Date Retirement 2050.',
      ),
      WealthAccount(
        id: uuid.v4(),
        institution: 'Vanguard Group',
        accountType: AccountType.investment,
        accountName: 'Emma & Liam 529 College Savings',
        maskedNumber: '•••• 7309',
        balance: 42100.00,
        assignedMember: 'Emma & Liam',
        notes: 'Dedicated for university tuition.',
      ),
      WealthAccount(
        id: uuid.v4(),
        institution: 'Apple Card / Goldman',
        accountType: AccountType.creditCard,
        accountName: 'Family Shared Master Card',
        maskedNumber: '•••• 3920',
        balance: 1850.30,
        assignedMember: 'Dad & Mom',
        notes: 'Paid off in full each billing cycle.',
      ),
    ];

    // 3. Vehicles & Maintenance
    _vehicles = [
      Vehicle(
        id: uuid.v4(),
        nickname: 'Family Roadtrip SUV',
        make: 'Toyota',
        model: 'Highlander Hybrid AWD',
        year: 2022,
        licensePlate: '7ABC892',
        vin: '4T3BKRBH8NU198241',
        currentMileage: 38450,
        oilChangeDueMileage: 40000,
        registrationExpiry: DateTime.now().add(const Duration(days: 24)), // EXPIRES SOON!
        insuranceCompany: 'GEICO Auto',
        insurancePolicyNumber: 'POL-992014-CA',
        insuranceExpiry: DateTime.now().add(const Duration(days: 140)),
        assignedMember: 'Entire Family',
        estimatedValue: 34500.0,
        logs: [
          MaintenanceLog(
            id: uuid.v4(),
            serviceType: 'Synthetic Oil & Filter Change',
            date: DateTime.now().subtract(const Duration(days: 90)),
            mileage: 35000,
            cost: 89.50,
            serviceCenter: 'Toyota Certified Care',
            notes: 'Replaced cabin air filter and rotated tires.',
          ),
        ],
      ),
      Vehicle(
        id: uuid.v4(),
        nickname: 'Dad\'s Commuter EV',
        make: 'Tesla',
        model: 'Model Y Long Range',
        year: 2023,
        licensePlate: '9XYZ104',
        vin: '7SAYGDEE9PF190342',
        currentMileage: 21800,
        oilChangeDueMileage: 0, // EV
        registrationExpiry: DateTime.now().add(const Duration(days: 210)),
        insuranceCompany: 'GEICO Auto',
        insurancePolicyNumber: 'POL-992014-CA',
        insuranceExpiry: DateTime.now().add(const Duration(days: 140)),
        assignedMember: 'Robert (Dad)',
        estimatedValue: 38000.0,
        logs: [
          MaintenanceLog(
            id: uuid.v4(),
            serviceType: 'Tire Rotation & Brake Inspection',
            date: DateTime.now().subtract(const Duration(days: 45)),
            mileage: 20000,
            cost: 45.00,
            serviceCenter: 'Tesla Service Center',
          ),
        ],
      ),
    ];

    // 4. Properties & Real Estate (with map coordinates)
    _properties = [
      PropertyAsset(
        id: uuid.v4(),
        title: 'Family Primary Residence',
        propertyType: 'Single Family Residence',
        fullAddress: '2418 Willow Creek Dr, Austin, TX 78704',
        latitude: 30.2450,
        longitude: -97.7550,
        purchasePrice: 420000.0,
        estimatedMarketValue: 615000.0,
        mortgageRemaining: 285000.0,
        parcelNumber: 'TX-TRAVIS-041928',
        propertyTaxDueDate: DateTime.now().add(const Duration(days: 65)),
        assignedMember: 'Robert & Sarah',
        notes: '4 Beds, 3 Baths, 2,800 sq ft. Roof replaced in 2024. Deeds in safe deposit box.',
      ),
      PropertyAsset(
        id: uuid.v4(),
        title: 'Hill Country Land & Cabin',
        propertyType: 'Recreational Land (5 Acres)',
        fullAddress: '109 Lakeshore Blvd, Lake Travis, TX 78645',
        latitude: 30.4180,
        longitude: -97.9820,
        purchasePrice: 160000.0,
        estimatedMarketValue: 245000.0,
        mortgageRemaining: 45000.0,
        parcelNumber: 'TX-BURNET-88201',
        assignedMember: 'Entire Family',
        notes: 'Includes private boat slip and solar well pump.',
      ),
    ];

    // 5. Warranties & Receipts
    _warranties = [
      WarrantyReceipt(
        id: uuid.v4(),
        itemName: 'LG 28 cu. ft. Smart French Door Refrigerator',
        category: 'Appliances',
        storeMerchant: 'The Home Depot',
        purchaseDate: DateTime.now().subtract(const Duration(days: 300)),
        price: 2499.00,
        warrantyPeriodMonths: 24, // Active!
        serialNumber: 'LG-REF-8941092',
        receiptNumber: 'HD-99402194',
        assignedMember: 'Entire Family',
        notes: 'Includes 5-year compressor manufacturer warranty.',
      ),
      WarrantyReceipt(
        id: uuid.v4(),
        itemName: 'Samsung 65" OLED 4K Smart TV',
        category: 'Electronics',
        storeMerchant: 'Best Buy',
        purchaseDate: DateTime.now().subtract(const Duration(days: 180)),
        price: 1799.99,
        warrantyPeriodMonths: 24, // Geek Squad Protection
        serialNumber: 'SAM-QN65S90C-1029',
        receiptNumber: 'BBY-01-94821',
        assignedMember: 'Living Room',
        notes: 'Covers burn-in and screen replacement.',
      ),
      WarrantyReceipt(
        id: uuid.v4(),
        itemName: 'MacBook Pro 16" M3 Max',
        category: 'Electronics',
        storeMerchant: 'Apple Store',
        purchaseDate: DateTime.now().subtract(const Duration(days: 120)),
        price: 3499.00,
        warrantyPeriodMonths: 36, // AppleCare+
        serialNumber: 'C02ZF09PMD6V',
        assignedMember: 'Robert (Dad)',
        notes: 'AppleCare+ expires in 2+ years. Covers accidental damage.',
      ),
    ];

    // 6. Passports, Wills & Vital Documents
    _items = [
      VaultItem(
        id: uuid.v4(),
        title: 'Dad\'s US Passport & Global Entry',
        category: VaultCategory.document,
        username: 'Passport #: P98302184 | PASSID: 984029104',
        password: 'Place of Birth: Ohio, USA',
        url: 'National Passport Center',
        assignedMember: 'Robert (Dad)',
        expiryDate: '08/2031',
        notes: 'Book stored in safe deposit box #214. Digital scan backed up.',
        isFavorite: true,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Mom\'s Schengen Multiple-Entry Visa',
        category: VaultCategory.document,
        username: 'Visa #: VSA-883921-FR',
        password: 'Type: C (Multi-Entry Tourism & Business)',
        url: 'French Consulate General',
        assignedMember: 'Sarah (Mom)',
        expiryDate: '05/2027',
        notes: 'Allows up to 90 days stay in any 180-day period.',
        isFavorite: true,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Family Living Trust & Last Will',
        category: VaultCategory.legal,
        username: 'The Miller Family Revocable Trust dated 2021',
        password: 'Trustees: Robert & Sarah | Successor Trustee: Uncle David',
        url: 'Austin Estate Law Partners, PLLC',
        assignedMember: 'Entire Family',
        notes: 'Physical executed originals in fireproof safe. Pour-over wills and durable medical powers of attorney attached.',
        isFavorite: true,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Home Wi-Fi (Family Mesh)',
        category: VaultCategory.wifi,
        username: 'FamilyVault_5GHz',
        password: 'GoldenOak#2026!Key',
        url: '192.168.1.1',
        assignedMember: 'Entire Family',
        notes: 'Main router located in living room.',
        isFavorite: true,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Emergency Pediatrician (Dr. Miller)',
        category: VaultCategory.emergency,
        username: 'Clinic: (555) 392-1084',
        password: 'Cell: (555) 981-3420',
        url: 'Children\'s Health Center, Suite 400',
        assignedMember: 'Kids',
        notes: 'Blood Type: O+ | Allergy Alert: Penicillin & Peanuts',
        isFavorite: true,
      ),
    ];

    await saveVaultBundle();
  }
}
