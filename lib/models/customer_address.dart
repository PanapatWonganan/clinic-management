class CustomerAddress {
  final String id;
  final String name;
  final String recipientName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String district;
  final String province;
  final String postalCode;
  final int provinceId;
  final int districtId;
  final int subDistrictId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerAddress({
    required this.id,
    required this.name,
    required this.recipientName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.provinceId,
    required this.districtId,
    required this.subDistrictId,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      provinceId: int.tryParse(json['province_id'].toString()) ?? 0,
      districtId: int.tryParse(json['district_id'].toString()) ?? 0,
      subDistrictId: int.tryParse(json['sub_district_id'].toString()) ?? 0,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'recipient_name': recipientName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'district': district,
      'province': province,
      'postal_code': postalCode,
      'province_id': provinceId,
      'district_id': districtId,
      'sub_district_id': subDistrictId,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get full formatted address
  String get fullAddress {
    List<String> parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      district,
      province,
      postalCode,
    ];
    return parts.join(', ');
  }

  // Get short address for display
  String get shortAddress {
    List<String> parts = [
      district,
      province,
      postalCode,
    ];
    return parts.join(', ');
  }

  // Create a copy with modified fields
  CustomerAddress copyWith({
    String? id,
    String? name,
    String? recipientName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? district,
    String? province,
    String? postalCode,
    int? provinceId,
    int? districtId,
    int? subDistrictId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      district: district ?? this.district,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      provinceId: provinceId ?? this.provinceId,
      districtId: districtId ?? this.districtId,
      subDistrictId: subDistrictId ?? this.subDistrictId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomerAddress{id: $id, name: $name, recipientName: $recipientName, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerAddress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}