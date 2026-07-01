import 'package:flutter/material.dart';

class RewardProduct {
  final int id;
  final String name;
  final String? description;
  final int points;
  final String? image;
  final int stock;

  const RewardProduct({
    required this.id,
    required this.name,
    this.description,
    required this.points,
    this.image,
    required this.stock,
  });

  factory RewardProduct.fromJson(Map<String, dynamic> json) {
    return RewardProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      image: (json['image'] as String?)?.isNotEmpty == true
          ? json['image'] as String
          : null,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  /// Temporary icon shown until the team supplies a real image. Keyed by name.
  IconData get fallbackIcon {
    final n = name.toLowerCase();
    if (n.contains('หมวก')) return Icons.sports_baseball;
    if (n.contains('กระเป๋า')) return Icons.shopping_bag;
    if (n.contains('babytee') || n.contains('oversize') || n.contains('เสื้อ')) {
      return Icons.checkroom;
    }
    if (n.contains('vdo') || n.contains('marketing')) return Icons.videocam;
    if (n.contains('insurance')) return Icons.shield;
    if (n.contains('hand-ons') || n.contains('1:1')) return Icons.handshake;
    if (n.contains('lecture') || n.contains('training')) return Icons.school;
    if (n.contains('ticket')) return Icons.airplane_ticket;
    if (n.contains('trip') || n.contains('travel')) return Icons.flight_takeoff;
    return Icons.card_giftcard;
  }
}
