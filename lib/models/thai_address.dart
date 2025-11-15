class Province {
  final int id;
  final String nameTh;
  final String nameEn;

  Province({
    required this.id,
    required this.nameTh,
    required this.nameEn,
  });

  String get name => nameTh;

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'],
      nameTh: json['name_th'],
      nameEn: json['name_en'],
    );
  }
}

class District {
  final int id;
  final int provinceId;
  final String nameTh;
  final String nameEn;

  District({
    required this.id,
    required this.provinceId,
    required this.nameTh,
    required this.nameEn,
  });

  String get name => nameTh;

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      provinceId: json['province_id'],
      nameTh: json['name_th'],
      nameEn: json['name_en'],
    );
  }
}

class SubDistrict {
  final int id;
  final int districtId;
  final String nameTh;
  final String nameEn;
  final String postalCode;

  SubDistrict({
    required this.id,
    required this.districtId,
    required this.nameTh,
    required this.nameEn,
    required this.postalCode,
  });

  factory SubDistrict.fromJson(Map<String, dynamic> json) {
    return SubDistrict(
      id: json['id'],
      districtId: json['district_id'],
      nameTh: json['name_th'],
      nameEn: json['name_en'],
      postalCode: json['postal_code'],
    );
  }
}