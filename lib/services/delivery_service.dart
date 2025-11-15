import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/delivery_option.dart';
import '../constants/app_config.dart';

class DeliveryService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Test API connection
  static Future<void> testApiConnection() async {
    try {
      debugPrint('Testing API connection to $baseUrl');
      
      // Test 1: Bangkok district
      final bangkokOptions = await getDeliveryOptions('แขวงจตุจักร');
      debugPrint('Bangkok test - จตุจักร options count: ${bangkokOptions.length}');
      if (bangkokOptions.isNotEmpty) {
        debugPrint('Sample price - Grab car: ${bangkokOptions.firstWhere((o) => o.company == DeliveryCompany.grab && o.vehicleType == VehicleType.car).price}');
      }

      // Test 2: Suburban district using unified API
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/unified-options'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'location_name': 'อำเภอบางพลี',
          'province_name': 'สมุทรปราการ',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Suburban test - บางพลี response: ${data['success']}');
        if (data['success']) {
          final options = data['data']['delivery_options'] as List;
          final grabCarPrice = options.firstWhere((o) => o['company'] == 'grab' && o['vehicle_type'] == 'car')['price'];
          debugPrint('Sample suburban price - Grab car: $grabCarPrice');
        }
      }

      debugPrint('API connection test completed');
    } catch (e) {
      debugPrint('API connection test failed: $e');
    }
  }

  /// Get all available districts for delivery
  static Future<List<String>> getAvailableDistricts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/districts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data']);
        }
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      return [];
    }
  }

  /// Get delivery options for a specific district
  static Future<List<DeliveryOption>> getDeliveryOptions(String districtName) async {
    try {
      // Encode district name for URL
      final encodedDistrict = Uri.encodeComponent(districtName);
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/options/$encodedDistrict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> optionsJson = data['data']['delivery_options'];
          return optionsJson.map((json) => DeliveryOption.fromJson(json)).toList();
        }
      }
      
      // Return sample data if API fails
      return DeliveryOption.getSampleOptions();
    } catch (e) {
      debugPrint('Error fetching delivery options: $e');
      // Return sample data if API fails
      return DeliveryOption.getSampleOptions();
    }
  }

  /// Get specific delivery price
  static Future<double?> getDeliveryPrice({
    required String districtName,
    required String company,
    required String vehicleType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/price'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'district_name': districtName,
          'company': company,
          'vehicle_type': vehicleType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return double.parse(data['data']['price'].toString());
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching delivery price: $e');
      return null;
    }
  }

  /// Check if district has delivery service
  static Future<bool> isDeliveryAvailable(String districtName) async {
    final districts = await getAvailableDistricts();
    return districts.contains(districtName);
  }

  /// Get delivery options based on user's address (district and province)
  static Future<List<DeliveryOption>> getDeliveryOptionsForAddress(String? userDistrict, [String? userProvince]) async {
    if (userDistrict == null || userDistrict.isEmpty) {
      // Return sample options if no district specified
      return DeliveryOption.getSampleOptions();
    }

    // First try unified search (works for both Bangkok and provinces)
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/unified-options'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'location_name': userDistrict,
          'province_name': userProvince,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> optionsJson = data['data']['delivery_options'];
          return optionsJson.map((json) => DeliveryOption.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error with unified search: $e');
    }
    
    // Fallback to original method for Bangkok districts
    return await getDeliveryOptions(userDistrict);
  }

  /// Get delivery options for provinces (Samut Prakan, Pathum Thani, Nonthaburi)  
  static Future<List<DeliveryOption>> getDeliveryOptionsForProvince(String provinceName, String districtName) async {
    try {
      // Encode names for URL
      final encodedProvince = Uri.encodeComponent(provinceName);
      final encodedDistrict = Uri.encodeComponent(districtName);
      
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/provinces/$encodedProvince/districts/$encodedDistrict/options'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> optionsJson = data['data']['delivery_options'];
          return optionsJson.map((json) => DeliveryOption.fromJson(json)).toList();
        }
      }
      
      return DeliveryOption.getSampleOptions();
    } catch (e) {
      debugPrint('Error fetching province delivery options: $e');
      return DeliveryOption.getSampleOptions();
    }
  }
}