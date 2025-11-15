class UserProfile {
  String name;
  String email;
  String phone;
  String address;
  String district;
  String province;
  String postalCode;
  
  // New Thai address fields
  int? provinceId;
  int? districtId;
  int? subDistrictId;

  UserProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.district = '',
    this.province = '',
    this.postalCode = '',
    this.provinceId,
    this.districtId,
    this.subDistrictId,
  });

  // ฟังก์ชันสำหรับสร้าง UserProfile จาก Map (สำหรับ SharedPreferences)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
      provinceId: map['provinceId'],
      districtId: map['districtId'],
      subDistrictId: map['subDistrictId'],
    );
  }

  // ฟังก์ชันสำหรับแปลง UserProfile เป็น Map (สำหรับ SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'district': district,
      'province': province,
      'postalCode': postalCode,
      'provinceId': provinceId,
      'districtId': districtId,
      'subDistrictId': subDistrictId,
    };
  }

  // ฟังก์ชันตรวจสอบว่าที่อยู่ครบถ้วนหรือไม่
  bool get hasCompleteAddress {
    return name.isNotEmpty &&
        phone.isNotEmpty &&
        address.isNotEmpty &&
        district.isNotEmpty &&
        province.isNotEmpty &&
        postalCode.isNotEmpty;
  }

  // ฟังก์ชันสำหรับดึงที่อยู่แบบเต็ม
  String get fullAddress {
    if (!hasCompleteAddress) return 'ยังไม่ได้กรอกข้อมูล';
    return '$address\n$district $province $postalCode';
  }
}
