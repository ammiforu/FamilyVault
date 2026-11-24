import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import 'encryption_service.dart';

class StorageService {
  static const String _keyPinHash = 'master_pin_hash';
  static const String _keyHasSetup = 'vault_is_setup';
  static const String _vaultFileName = 'family_vault_data.enc';

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  List<VaultItem> _items = [];
  String _currentSessionPin = '';

  List<VaultItem> get items => List.unmodifiable(_items);

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

    if (_items.isEmpty) {
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

  Future<File> _getLocalVaultFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_vaultFileName');
  }

  Future<void> loadVaultItems() async {
    try {
      final file = await _getLocalVaultFile();
      if (!await file.exists()) {
        await _seedDefaultDemoData();
        return;
      }

      final encryptedContent = await file.readAsString();
      if (encryptedContent.trim().isEmpty) {
        await _seedDefaultDemoData();
        return;
      }

      final plainJson = EncryptionService.decryptPayload(encryptedContent, _currentSessionPin);
      if (plainJson.isEmpty) {
        return;
      }

      final List<dynamic> jsonList = json.decode(plainJson) as List<dynamic>;
      _items = jsonList.map((e) => VaultItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      if (_items.isEmpty) {
        await _seedDefaultDemoData();
      }
    }
  }

  Future<void> saveVaultItems() async {
    try {
      final file = await _getLocalVaultFile();
      final jsonString = json.encode(_items.map((e) => e.toJson()).toList());
      final encryptedContent = EncryptionService.encryptPayload(jsonString, _currentSessionPin);
      await file.writeAsString(encryptedContent, flush: true);
    } catch (_) {}
  }

  Future<void> addItem(VaultItem item) async {
    _items.insert(0, item);
    await saveVaultItems();
  }

  Future<void> updateItem(VaultItem item) async {
    final index = _items.indexWhere((it) => it.id == item.id);
    if (index != -1) {
      _items[index] = item;
      await saveVaultItems();
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((it) => it.id == id);
    await saveVaultItems();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((it) => it.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isFavorite: !_items[index].isFavorite);
      await saveVaultItems();
    }
  }

  String exportToCsv() {
    final List<List<dynamic>> rows = [
      VaultItem.csvHeaders(),
      ..._items.map((e) => e.toCsvRow()),
    ];
    return rows.map((row) => row.map((cell) {
      final str = cell?.toString() ?? '';
      if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
        return '"${str.replaceAll('"', '""')}"';
      }
      return str;
    }).join(',')).join('\n');
  }

  Future<int> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split(RegExp(r'\r?\n'));
      if (lines.length <= 1) return 0;

      int importedCount = 0;
      const uuid = Uuid();

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final row = _parseCsvLine(line);
        if (row.isEmpty || row[0].isEmpty) continue;

        final newItem = VaultItem.fromCsvRow(row, uuid.v4());
        _items.add(newItem);
        importedCount++;
      }

      await saveVaultItems();
      return importedCount;
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

  Future<void> _seedDefaultDemoData() async {
    const uuid = Uuid();
    _items = [
      VaultItem(
        id: uuid.v4(),
        title: 'Home Wi-Fi (Family Mesh)',
        category: VaultCategory.wifi,
        username: 'FamilyVault_5GHz',
        password: 'GoldenOak#2026!Key',
        url: '192.168.1.1',
        assignedMember: 'Entire Family',
        notes: 'Main router located in living room. Guest network password is Guest@Vault2026',
        isFavorite: true,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Netflix 4K Ultra HD',
        category: VaultCategory.login,
        username: 'family.stream@gmail.com',
        password: 'Watch#Movies!993',
        url: 'https://netflix.com',
        assignedMember: 'Entire Family',
        notes: 'Premium 4 Screens. Profile 1: Dad, 2: Mom, 3: Kids',
        isFavorite: true,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Chase Family Sapphire Card',
        category: VaultCategory.card,
        username: 'Card Ending in 4821',
        password: 'CVV: 739 | PIN: 8402',
        url: 'https://chase.com',
        assignedMember: 'Dad & Mom',
        expiryDate: '11/2028',
        notes: 'Used for groceries, travel points, and family emergencies.',
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
      VaultItem(
        id: uuid.v4(),
        title: 'Family Health Insurance (BlueCross)',
        category: VaultCategory.document,
        username: 'Policy: BCX-89302194',
        password: 'Group #: GRP-48201',
        url: 'https://bcbs.com/portal',
        assignedMember: 'Entire Family',
        expiryDate: '12/2026',
        notes: 'Primary Subscriber: Dad | Covers dental, vision, and full medical.',
        isFavorite: false,
      ),
      VaultItem(
        id: uuid.v4(),
        title: 'Safe Deposit Box & House Alarm',
        category: VaultCategory.note,
        username: 'Box #214 at Downtown Branch',
        password: 'Key Location: Study Desk Top Drawer | Alarm Code: 4910',
        url: 'Home Security Panel',
        assignedMember: 'Mom & Dad',
        notes: 'Contains property deeds, birth certificates, and spare vehicle titles.',
        isFavorite: false,
      ),
    ];
    await saveVaultItems();
  }
}
