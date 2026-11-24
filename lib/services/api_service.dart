import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  /// Search real addresses using OpenStreetMap Nominatim (free, no API key),
  /// with automatic fallback to Komoot Photon API.
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    // Try Photon first (fast, no strict User-Agent throttling, great autocomplete)
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(trimmed)}&limit=6',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        final results = <AddressSuggestion>[];
        for (final f in features) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final geom = f['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List<dynamic>? ?? [];
          if (coords.length < 2) continue;

          final parts = <String>[
            if (props['housenumber'] != null && props['street'] != null)
              '${props['housenumber']} ${props['street']}'
            else if (props['name'] != null)
              props['name'].toString()
            else if (props['street'] != null)
              props['street'].toString(),
            if (props['city'] != null) props['city'].toString(),
            if (props['state'] != null) props['state'].toString(),
            if (props['postcode'] != null) props['postcode'].toString(),
            if (props['country'] != null) props['country'].toString(),
          ];
          final label = parts.where((p) => p.isNotEmpty).join(', ');
          if (label.isNotEmpty) {
            results.add(AddressSuggestion(
              displayName: label,
              longitude: (coords[0] as num).toDouble(),
              latitude: (coords[1] as num).toDouble(),
            ));
          }
        }
        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    // Fallback to OpenStreetMap Nominatim
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmed)}&format=json&addressdetails=1&limit=6',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'FamilyVaultApp/1.0 (local-first-family-vault)',
      }).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
        return list.map((item) {
          return AddressSuggestion(
            displayName: item['display_name'] as String? ?? '',
            latitude: double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
            longitude: double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
          );
        }).where((a) => a.displayName.isNotEmpty).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Reverse geocode lat/lng to human-readable address when tapping the map.
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'FamilyVaultApp/1.0 (local-first-family-vault)',
      }).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final display = data['display_name'] as String?;
        if (display != null && display.isNotEmpty) return display;
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// Fetch live free exchange rates relative to USD.
  Future<Map<String, double>> fetchExchangeRates({String base = 'USD'}) async {
    try {
      final uri = Uri.parse('https://open.er-api.com/v6/latest/$base');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>? ?? {};
        return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
    } catch (_) {}
    return {'USD': 1.0, 'EUR': 0.92, 'GBP': 0.79, 'INR': 84.0, 'CAD': 1.39, 'AUD': 1.53};
  }

  /// Fetch CSV content directly from a shared Google Sheets URL.
  Future<({bool success, String content, String error})> fetchGoogleSheetCsv(String url) async {
    try {
      final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
      final match = regex.firstMatch(url);
      if (match == null) {
        return (success: false, content: '', error: 'Invalid Google Sheets URL format.');
      }
      final sheetId = match.group(1)!;
      final gidMatch = RegExp(r'gid=(\d+)').firstMatch(url);
      final gid = gidMatch?.group(1) ?? '0';

      final exportUrl = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv&gid=$gid',
      );
      final resp = await http.get(exportUrl).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final body = resp.body;
        if (body.trimLeft().startsWith('<!DOCTYPE html>') || body.contains('accounts.google.com/ServiceLogin')) {
          return (
            success: false,
            content: '',
            error: 'This Google Sheet is private. Set sharing to "Anyone with the link can view" or copy-paste the CSV rows directly.',
          );
        }
        return (success: true, content: body, error: '');
      }
      return (success: false, content: '', error: 'HTTP ${resp.statusCode}: Could not download sheet.');
    } catch (e) {
      return (success: false, content: '', error: 'Network error: $e');
    }
  }
}
