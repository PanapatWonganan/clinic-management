import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/reward_product.dart';
import '../models/reward_redemption.dart';
import 'api_service.dart';

class RewardException implements Exception {
  final String message;
  RewardException(this.message);
  @override
  String toString() => message;
}

class RewardService {
  static final RewardService instance = RewardService._internal();
  RewardService._internal();

  Future<List<RewardProduct>> getRewardCatalog() async {
    final response = await ApiService.get('/reward-catalog');
    final data = _parseResponse(response);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((j) => RewardProduct.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw RewardException(data['message']?.toString() ?? 'โหลดของรางวัลไม่สำเร็จ');
  }

  Future<int> getPointsBalance() async {
    final response = await ApiService.get('/reward-points/balance');
    final data = _parseResponse(response);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data']['points_balance'] as num?)?.toInt() ?? 0;
    }
    throw RewardException(data['message']?.toString() ?? 'โหลดคะแนนไม่สำเร็จ');
  }

  Future<RewardRedemption> redeem({
    required int productId,
    required int quantity,
    required String shippingAddressId,
    String? notes,
  }) async {
    final response = await ApiService.post('/reward-redemptions', {
      'product_id': productId,
      'quantity': quantity,
      'shipping_address_id': int.tryParse(shippingAddressId) ?? shippingAddressId,
      if (notes != null) 'notes': notes,
    });
    final data = _parseResponse(response);
    if (response.statusCode == 201 && data['success'] == true) {
      return RewardRedemption.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw RewardException(data['message']?.toString() ?? 'แลกของรางวัลไม่สำเร็จ');
  }

  Future<List<RewardRedemption>> getRedemptionHistory() async {
    final response = await ApiService.get('/reward-redemptions');
    final data = _parseResponse(response);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((j) => RewardRedemption.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw RewardException(data['message']?.toString() ?? 'โหลดประวัติไม่สำเร็จ');
  }

  /// Parse response body without status code validation.
  /// This allows the caller to check status and decide on success/failure.
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Invalid response format'};
    }
  }
}
