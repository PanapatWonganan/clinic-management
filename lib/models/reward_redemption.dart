class RewardRedemption {
  final int id;
  final int productId;
  final String? productName;
  final int quantity;
  final int pointsTotal;
  final String status;
  final String statusLabel;
  final String? trackingNumber;
  final String createdAt;

  const RewardRedemption({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.pointsTotal,
    required this.status,
    required this.statusLabel,
    this.trackingNumber,
    required this.createdAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['id'] as int,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      pointsTotal: (json['points_total'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? '',
      trackingNumber: json['tracking_number'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
