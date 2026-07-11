import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/google_maps_config.dart';

class ValidatedAddress {
  const ValidatedAddress({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? placeId;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.description,
    required this.placeId,
  });

  final String description;
  final String placeId;
}

class GooglePlacesService {
  GooglePlacesService._();
  static final GooglePlacesService instance = GooglePlacesService._();

  static const _base = 'https://maps.googleapis.com/maps/api';

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 3) return [];

    final uri = Uri.parse('$_base/place/autocomplete/json').replace(
      queryParameters: {
        'input': query,
        'key': GoogleMapsConfig.apiKey,
        'components': 'country:au',
        'types': 'geocode',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        debugPrint('Places autocomplete: ${data['status']}');
        return [];
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions
          .map(
            (item) => PlaceSuggestion(
              description: item['description'] as String? ?? '',
              placeId: item['place_id'] as String? ?? '',
            ),
          )
          .where((item) => item.description.isNotEmpty && item.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Places autocomplete failed: $e');
      return [];
    }
  }

  Future<ValidatedAddress?> placeDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    final uri = Uri.parse('$_base/place/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'formatted_address,geometry',
        'key': GoogleMapsConfig.apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint('Place details: ${data['status']}');
        return null;
      }

      return _parseResult(data['result'] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('Place details failed: $e');
      return null;
    }
  }

  Future<ValidatedAddress?> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    final uri = Uri.parse('$_base/geocode/json').replace(
      queryParameters: {
        'address': query,
        'key': GoogleMapsConfig.apiKey,
        'components': 'country:AU',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint('Geocode: ${data['status']}');
        return null;
      }

      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;
      return _parseResult(results.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Geocode failed: $e');
      return null;
    }
  }

  Future<ValidatedAddress?> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.parse('$_base/geocode/json').replace(
      queryParameters: {
        'latlng': '$latitude,$longitude',
        'key': GoogleMapsConfig.apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;
      return _parseResult(results.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
      return null;
    }
  }

  ValidatedAddress? _parseResult(Map<String, dynamic>? result) {
    if (result == null) return null;

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return ValidatedAddress(
      formattedAddress:
          result['formatted_address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      placeId: result['place_id'] as String?,
    );
  }
}
