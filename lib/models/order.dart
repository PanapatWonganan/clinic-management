import 'package:flutter/material.dart';
import '../constants/app_config.dart';

class Order {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final OrderStatus status;
  final List<OrderItem> items;
  final String deliveryMethod;
  final String paymentMethod;
  final String? trackingNumber;
  final DeliveryProof? deliveryProof;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.deliveryMethod,
    required this.paymentMethod,
    this.trackingNumber,
    this.deliveryProof,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      orderDate: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: _parseOrderStatus(json['status']),
      items: (json['order_items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      deliveryMethod: json['delivery_method'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      trackingNumber: json['tracking_number'],
      deliveryProof: json['delivery_proof'] != null 
          ? DeliveryProof.fromJson(json['delivery_proof'])
          : null,
    );
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending_payment':
        return OrderStatus.pending;
      case 'payment_uploaded':
        return OrderStatus.pending;
      case 'paid':
        return OrderStatus.confirmed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imagePath;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imagePath,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};

    // Use image_url from backend, fallback to name-based mapping
    String imageUrl = product['image_url'] ?? '';
    String imagePath;

    if (imageUrl.isNotEmpty) {
      // Extract relative path from full URL if needed
      if (imageUrl.contains('/storage/')) {
        // Extract path after /storage/
        final relativePath = imageUrl.split('/storage/').last;
        imagePath = '${AppConfig.storageBaseUrl}/$relativePath';
      } else if (imageUrl.startsWith('http')) {
        // Already a full URL, use as is
        imagePath = imageUrl;
      } else {
        // Relative path, prepend storage base URL
        imagePath = '${AppConfig.storageBaseUrl}/$imageUrl';
      }
    } else {
      // Fallback: map from product name (legacy behavior)
      imagePath = _getImagePath(product['name']);
    }

    return OrderItem(
      id: json['id'].toString(),
      name: product['name'] ?? 'Unknown Product',
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['unit_price'].toString()),
      imagePath: imagePath,
    );
  }

  static String _getImagePath(String? productName) {
    if (productName == null) return 'assets/images/mask-group.png';
    
    final name = productName.toLowerCase();
    if (name.contains('fine') || name.contains('บาง')) {
      return 'assets/images/mask-group.png';
    } else if (name.contains('deep') || name.contains('กลาง')) {
      return 'assets/images/mask-group-1.png';
    } else if (name.contains('sub-q') || name.contains('โวลุ่ม')) {
      return 'assets/images/mask-group-2.png';
    } else if (name.contains('implant') || name.contains('แข็ง')) {
      return 'assets/images/mask-group-3.png';
    } else {
      return 'assets/images/mask-group.png';
    }
  }
}

class DeliveryProof {
  final String id;
  final String imageUrl;
  final String originalFilename;
  final String fileSizeFormatted;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? notes;

  DeliveryProof({
    required this.id,
    required this.imageUrl,
    required this.originalFilename,
    required this.fileSizeFormatted,
    required this.uploadedAt,
    required this.uploadedBy,
    this.notes,
  });

  factory DeliveryProof.fromJson(Map<String, dynamic> json) {
    return DeliveryProof(
      id: json['id'].toString(),
      imageUrl: json['image_url'] ?? '',
      originalFilename: json['original_filename'] ?? '',
      fileSizeFormatted: json['file_size_formatted'] ?? '',
      uploadedAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      uploadedBy: json['uploader']?['name'] ?? 'Admin',
      notes: json['notes'],
    );
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'รอดำเนินการ';
      case OrderStatus.confirmed:
        return 'ยืนยันแล้ว';
      case OrderStatus.processing:
        return 'กำลังเตรียม';
      case OrderStatus.shipped:
        return 'จัดส่งแล้ว';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.confirmed:
        return const Color(0xFF3B82F6);
      case OrderStatus.processing:
        return const Color(0xFF8B5CF6);
      case OrderStatus.shipped:
        return const Color(0xFF06B6D4);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFEF3C7);
      case OrderStatus.confirmed:
        return const Color(0xFFDBEAFE);
      case OrderStatus.processing:
        return const Color(0xFFEDE9FE);
      case OrderStatus.shipped:
        return const Color(0xFFCFFAFE);
    }
  }
}
