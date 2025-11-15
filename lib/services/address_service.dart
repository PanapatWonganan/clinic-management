import '../models/customer_address.dart';
import 'api_service.dart';

class AddressService {
  static Future<List<CustomerAddress>> fetchAddresses() async {
    try {
      final response = await ApiService.get('/addresses');
      final data = ApiService.parseResponse(response);

      if (data['success'] == true) {
        final addressesData = data['data'] as List;
        return addressesData
            .map((json) => CustomerAddress.fromJson(json))
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  static Future<CustomerAddress> fetchAddress(String id) async {
    try {
      final response = await ApiService.get('/addresses/$id');
      final data = ApiService.parseResponse(response);

      if (data['success'] == true) {
        return CustomerAddress.fromJson(data['data']);
      }

      throw Exception('Address not found');
    } catch (e) {
      throw Exception('Failed to fetch address: $e');
    }
  }

  static Future<CustomerAddress> createAddress(
      Map<String, dynamic> addressData) async {
    try {
      final response = await ApiService.post('/addresses', addressData);
      final data = ApiService.parseResponse(response);

      if (data['success'] == true) {
        return CustomerAddress.fromJson(data['data']);
      }

      throw Exception(data['message'] ?? 'Failed to create address');
    } catch (e) {
      if (e
          .toString()
          .contains('คุณสามารถเพิ่มที่อยู่ได้สูงสุด 3 แห่งเท่านั้น')) {
        rethrow;
      }
      throw Exception('Failed to create address: $e');
    }
  }

  static Future<CustomerAddress> updateAddress(
      String id, Map<String, dynamic> addressData) async {
    try {
      final response = await ApiService.put('/addresses/$id', addressData);
      final data = ApiService.parseResponse(response);

      if (data['success'] == true) {
        return CustomerAddress.fromJson(data['data']);
      }

      throw Exception(data['message'] ?? 'Failed to update address');
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  static Future<void> deleteAddress(String id) async {
    try {
      final response = await ApiService.delete('/addresses/$id');
      final data = ApiService.parseResponse(response);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete address');
      }
    } catch (e) {
      if (e.toString().contains(
          'ไม่สามารถลบที่อยู่ได้ เนื่องจากต้องมีที่อยู่อย่างน้อย 1 แห่ง')) {
        rethrow;
      }
      throw Exception('Failed to delete address: $e');
    }
  }

  static Future<void> setDefaultAddress(String id) async {
    try {
      final response = await ApiService.put('/addresses/$id/set-default', {});
      final data = ApiService.parseResponse(response);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to set default address');
      }
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  // Validate postal code format
  static bool isValidPostalCode(String postalCode) {
    return RegExp(r'^\d{5}$').hasMatch(postalCode);
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Support Thai phone numbers: 08x-xxx-xxxx, 02-xxx-xxxx, etc.
    return RegExp(r'^(0[2-9])-?\d{3}-?\d{4}$|^(0[6-9])-?\d{4}-?\d{4}$')
        .hasMatch(phone.replaceAll('-', '').replaceAll(' ', ''));
  }

  // Format phone number
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      if (cleaned.startsWith('02') ||
          cleaned.startsWith('03') ||
          cleaned.startsWith('04') ||
          cleaned.startsWith('05') ||
          cleaned.startsWith('07')) {
        // Landline: 0x-xxx-xxxx
        return '${cleaned.substring(0, 2)}-${cleaned.substring(2, 5)}-${cleaned.substring(5)}';
      } else {
        // Mobile: 08x-xxx-xxxx or 09x-xxx-xxxx
        return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
      }
    }
    return phone; // Return original if can't format
  }

  // Get default address from list
  static CustomerAddress? getDefaultAddress(List<CustomerAddress> addresses) {
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return null;
    }
  }

  // Sort addresses with default first
  static List<CustomerAddress> sortAddresses(List<CustomerAddress> addresses) {
    final sorted = List<CustomerAddress>.from(addresses);
    sorted.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }
}
