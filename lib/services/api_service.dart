import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Search real addresses using ArcGIS World Geocoder (free, full residential
  /// house-number coverage + CORS enabled), with fallback to Photon & OpenStreetMap Nominatim.
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    // 1. ArcGIS World Geocoding Service (best for exact residential home addresses)
    try {
      final uri = Uri.parse(
        'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates'
        '?SingleLine=${Uri.encodeComponent(trimmed)}&f=json&maxLocations=6',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>? ?? [];
        final results = <AddressSuggestion>[];
        for (final c in candidates) {
          final addr = c['address'] as String? ?? '';
          final loc = c['location'] as Map<String, dynamic>?;
          if (addr.isNotEmpty && loc != null) {
            final lat = (loc['y'] as num?)?.toDouble();
            final lng = (loc['x'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              results.add(AddressSuggestion(
                displayName: addr,
                latitude: lat,
                longitude: lng,
              ));
            }
          }
        }
        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    // 2. Fallback: Komoot Photon (OpenStreetMap-based)
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

    // 3. Fallback: OpenStreetMap Nominatim (never set User-Agent on Web due to browser CORS restrictions)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trimmed)}&format=json&addressdetails=1&limit=6',
      );
      final resp = await http
          .get(
            uri,
            headers: kIsWeb ? null : {'User-Agent': 'FamilyVaultApp/1.0 (local-first-family-vault)'},
          )
          .timeout(const Duration(seconds: 6));

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
        'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/reverseGeocode'
        '?location=$lng,$lat&f=json',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        final matchAddr = addr?['Match_addr'] as String? ?? addr?['LongLabel'] as String?;
        if (matchAddr != null && matchAddr.isNotEmpty) return matchAddr;
      }
    } catch (_) {}

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final resp = await http
          .get(
            uri,
            headers: kIsWeb ? null : {'User-Agent': 'FamilyVaultApp/1.0 (local-first-family-vault)'},
          )
          .timeout(const Duration(seconds: 6));

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

  /// Query OpenStreetMap Overpass API for building footprint area (sq ft) & levels at (lat, lng).
  Future<({int squareFeet, int levels, int yearBuilt})> fetchOsmBuildingDetails(double lat, double lng) async {
    try {
      final query = '[out:json][timeout:6];way["building"](around:35,$lat,$lng);out geom;';
      final uri = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 7));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];
        if (elements.isNotEmpty) {
          final way = elements.first as Map<String, dynamic>;
          final tags = way['tags'] as Map<String, dynamic>? ?? {};
          final geom = way['geometry'] as List<dynamic>? ?? [];

          final levels = int.tryParse(tags['building:levels']?.toString() ?? '') ?? 1;
          final yearBuilt = int.tryParse(tags['start_date']?.toString().substring(0, 4) ?? '') ?? 0;

          if (geom.length >= 3) {
            // Compute spherical polygon area in square meters
            const earthRadius = 6378137.0;
            double area = 0.0;
            for (int i = 0; i < geom.length; i++) {
              final p1 = geom[i] as Map<String, dynamic>;
              final p2 = geom[(i + 1) % geom.length] as Map<String, dynamic>;
              final lat1 = (p1['lat'] as num).toDouble() * math.pi / 180.0;
              final lon1 = (p1['lon'] as num).toDouble() * math.pi / 180.0;
              final lat2 = (p2['lat'] as num).toDouble() * math.pi / 180.0;
              final lon2 = (p2['lon'] as num).toDouble() * math.pi / 180.0;
              area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
            }
            area = (area * earthRadius * earthRadius / 2.0).abs();
            final sqFt = (area * 10.7639 * levels).round();
            return (squareFeet: sqFt > 200 ? sqFt : 0, levels: levels, yearBuilt: yearBuilt);
          }
        }
      }
    } catch (_) {}
    return (squareFeet: 0, levels: 0, yearBuilt: 0);
  }

  /// Decode a 17-character VIN using the free US Government NHTSA vPIC API.
  Future<({bool success, String make, String model, int year, String bodyClass})> decodeVin(String vin) async {
    final cleaned = vin.trim().toUpperCase();
    if (cleaned.length < 11) {
      return (success: false, make: '', model: '', year: 0, bodyClass: '');
    }
    try {
      final uri = Uri.parse('https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/$cleaned?format=json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 7));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final results = data['Results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final row = results.first as Map<String, dynamic>;
          final make = row['Make']?.toString().trim() ?? '';
          final model = row['Model']?.toString().trim() ?? '';
          final year = int.tryParse(row['ModelYear']?.toString().trim() ?? '') ?? 0;
          final bodyClass = row['BodyClass']?.toString().trim() ?? '';
          if (make.isNotEmpty && year > 1950) {
            return (success: true, make: make, model: model, year: year, bodyClass: bodyClass);
          }
        }
      }
    } catch (_) {}
    return (success: false, make: '', model: '', year: 0, bodyClass: '');
  }

  /// Fetch real vehicle models for a given Make & Year from NHTSA vPIC API.
  Future<List<String>> fetchModelsForMakeYear(String make, int year) async {
    if (make.trim().isEmpty || year < 1980) return [];
    try {
      final uri = Uri.parse(
        'https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeYear/make/${Uri.encodeComponent(make.trim())}/modelyear/$year?format=json',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 7));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final results = data['Results'] as List<dynamic>? ?? [];
        final models = results
            .map((r) => r['Model_Name']?.toString().trim() ?? '')
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        return models;
      }
    } catch (_) {}
    return [];
  }

  /// Estimate realistic market value for a vehicle (user can adjust anytime).
  double estimateVehicleValue({
    required String make,
    required String model,
    required int year,
    int mileage = 0,
    String bodyClass = '',
  }) {
    final m = make.toLowerCase();
    final mod = '${model.toLowerCase()} ${bodyClass.toLowerCase()}';

    // Base new MSRP tier by brand
    double baseMsrp = 33000;
    if (m.contains('porsche') || m.contains('rivian') || m.contains('lucid')) {
      baseMsrp = 82000;
    } else if (m.contains('mercedes') || m.contains('bmw') || m.contains('audi') || m.contains('lexus') || m.contains('land rover') || m.contains('cadillac')) {
      baseMsrp = 58000;
    } else if (m.contains('tesla') || m.contains('volvo') || m.contains('acura') || m.contains('infiniti')) {
      baseMsrp = 49000;
    } else if (m.contains('toyota') || m.contains('honda') || m.contains('subaru') || m.contains('mazda') || m.contains('ford') || m.contains('gmc')) {
      baseMsrp = 35000;
    } else if (m.contains('hyundai') || m.contains('kia') || m.contains('nissan') || m.contains('chevrolet') || m.contains('volkswagen')) {
      baseMsrp = 31000;
    }

    // Adjust for vehicle class (Truck/SUV/EV vs compact)
    if (mod.contains('truck') || mod.contains('f-150') || mod.contains('silverado') || mod.contains('tahoe') || mod.contains('suburban') || mod.contains('sequoia')) {
      baseMsrp += 15000;
    } else if (mod.contains('suv') || mod.contains('highlander') || mod.contains('pilot') || mod.contains('model y') || mod.contains('model x') || mod.contains('4runner') || mod.contains('sienna')) {
      baseMsrp += 9000;
    } else if (mod.contains('civic') || mod.contains('corolla') || mod.contains('elantra') || mod.contains('sentra')) {
      baseMsrp -= 5000;
    }

    final currentYear = DateTime.now().year;
    final age = (currentYear - year).clamp(0, 25);

    double value = baseMsrp;
    for (int i = 0; i < age; i++) {
      final rate = i == 0 ? 0.13 : (i < 5 ? 0.09 : 0.07);
      value *= (1.0 - rate);
    }

    // Mileage adjustment vs expected 12,000 mi/year
    if (mileage > 0) {
      final expectedMileage = age * 12000;
      final diff = mileage - expectedMileage;
      value -= (diff / 1000.0) * 90.0;
    }

    final clamped = value.clamp(2500.0, 150000.0);
    // Round to nearest $100
    return (clamped / 100.0).round() * 100.0;
  }
}
